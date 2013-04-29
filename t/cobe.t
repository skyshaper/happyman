use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use File::Slurp qw(read_file);
use File::Temp;
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::Cobe');

describe 'The Cobe plugin' => sub {
    my $happyman;
    my $irc;
    my $tempdir;
    
    before each => sub {
        $irc = make_test_client();
        $tempdir = File::Temp->newdir();
        $happyman = make_happyman_with_plugin('App::Happyman::Plugin::Cobe', {
            brain => "$tempdir/cobe_test.sqlite"
        });
    };
    
    after each => sub {
        disconnect_and_wait($irc);
        $happyman->disconnect_and_wait();
    };
        
    describe 'with an empty brain' => sub {
        describe 'when addressed' => sub {
            before each => sub {
                $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'happyman: hello');
            };
        
            it 'tells the sender it does not know enough yet' => sub {
                my (undef, undef, $ircmsg) = wait_on_event_or_timeout($irc, 'publicmsg', 5);
                my $full_text = $ircmsg->{params}->[1];
                is($full_text, 'HMTest: I don\'t know enough to answer you yet!');
            };
        };
    };
    
    describe 'with a trained brain' => sub {
        before each => sub {
            for (1..20) {
                $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'Are you happy, man?');
            }
        };
        
        describe 'when addressed' => sub {
            before each => sub {
                $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'happyman: hello');
            };
        
            it 'gives the sender an answer' => sub {
                my (undef, undef, $ircmsg) = wait_on_event_or_timeout($irc, 'publicmsg', 30);
                my $full_text = $ircmsg->{params}->[1];
                is($full_text, 'HMTest: Are you happy, man?');
            };
        }
    };
};

runtests unless caller;
