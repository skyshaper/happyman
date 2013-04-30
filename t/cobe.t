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
    my ( $happyman, $irc, $tempdir );

    before sub {
        $irc      = make_test_client();
        $tempdir  = File::Temp->newdir();
        $happyman = make_happyman_with_plugin( 'App::Happyman::Plugin::Cobe',
            { brain => "$tempdir/cobe_test.sqlite" } );
    };

    after sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    describe 'with an empty brain' => sub {
        describe 'when addressed' => sub {
            before sub {
                $irc->send_chan(
                    '#happyman', 'PRIVMSG',
                    '#happyman', 'happyman: hello'
                );
            };

            it 'tells the sender it does not know enough yet' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ),
                    'HMTest: I don\'t know enough to answer you yet!' );
            };
        };
    };

    describe 'with a trained brain' => sub {
        before sub {
            for ( 1 .. 20 ) {
                $irc->send_chan(
                    '#happyman', 'PRIVMSG',
                    '#happyman', 'Are you happy, man?'
                );
            }
        };

        describe 'when addressed' => sub {
            before sub {
                $irc->send_chan(
                    '#happyman', 'PRIVMSG',
                    '#happyman', 'happyman: hello'
                );
            };

            it 'gives the sender an answer' => sub {
                is( wait_on_message_or_timeout( $irc, 30 ),
                    'HMTest: Are you happy, man?'
                );
            };
            }
    };
};

runtests unless caller;
