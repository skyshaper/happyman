use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent::IRC::Util qw(encode_ctcp);
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::NickReply');

describe 'The NickReply plugin' => sub {
    my $happyman;
    my $irc;

    before sub {
        $happyman = make_happyman_with_plugin( 'NickReply', {} );
        $irc = make_test_client();
    };

    after sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    describe 'when mentioned with nickname' => sub {

        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                'happyman' );
        };

        it 'should reply with sender\'s nickname' => sub {
            is( wait_on_message_or_timeout($irc), $irc->nick );
        };
    };

    describe 'when mentioned with nickname surrounded by whitespace' => sub {

        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                ' happyman ' );
        };

        it 'should reply with sender\'s nickname' => sub {
            is( wait_on_message_or_timeout($irc), $irc->nick );
        };
    };

    describe 'when receiving other messages' => sub {

        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman', 'foobar' );
        };

        it 'should not reply' => sub {
            ok( !wait_on_message_or_timeout($irc) );
        };
    };
};

runtests unless caller;
