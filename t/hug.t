use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent::IRC::Util qw(encode_ctcp);
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::Hug');

describe 'The Hug plugin' => sub {
    my $happyman;
    my $irc;

    before sub {
        $happyman = make_happyman_with_plugin( 'Hug', {} );
        $irc = make_test_client();
    };

    after sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    describe 'when hugged by a user' => sub {

        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                encode_ctcp( [ 'ACTION', 'hugs happyman' ] ) );
        };

        it 'should hug the sender back' => sub {
            is( wait_on_action_or_timeout($irc), "hugs " . $irc->nick );
        };
    };

    describe 'when receiving other actions' => sub {

        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
            encode_ctcp( [ 'ACTION', 'foobar' ] ) );
        };

        it 'should not reply' => sub {
            ok( !wait_on_message_or_timeout($irc) );
        };
    };
};

runtests unless caller;
