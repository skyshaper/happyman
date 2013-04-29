use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::NickReply');

describe 'The NickReply plugin' => sub {
    my $happyman;
    my $irc;
    
    before each => sub {
        $happyman = make_happyman_with_plugin('App::Happyman::Plugin::NickReply', {});
        $irc = make_test_client();
    };
    
    after each => sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };
    
    describe 'when mentioned with nickname' => sub {
        my $ircmsg;
        
        before each => sub {
            $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'happyman');
            (undef, undef, $ircmsg) = wait_on_event_or_timeout($irc, 'publicmsg', 5);  
        };
    
        it 'should reply with sender\'s nickname' => sub {
            if ($ircmsg) {
                my $full_text = $ircmsg->{params}->[1];
                is($full_text, $irc->nick);
            }
            else {
                fail();
            }
        };
    };
    
    describe 'when receiving other messages' => sub {
        my $ircmsg;
                
        before each => sub {
            $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'foobar');
            (undef, undef, $ircmsg) = wait_on_event_or_timeout($irc, 'publicmsg', 5);
        };
        
        it 'should not reply' => sub {
            if ($ircmsg) {
                fail();
            }
            else {
                pass();
            }
        };
    };
};

runtests unless caller;
