use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::PeekURI');

describe 'PeekURI' => sub {
    my ( $happyman, $irc );

    before sub {
        my $config = load_local_config();
        $happyman
            = make_happyman_with_plugin( 'App::Happyman::Plugin::PeekURI',
            $config->{PeekURI} );
        $irc = make_test_client();
    };

    after sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    describe 'when seeing a Wikipedia URI' => sub {
        before sub {
            $irc->send_chan(
                '#happyman', 'PRIVMSG',
                '#happyman', 'http://en.wikipedia.org/wiki/Foo'
            );
        };

        it 'does not react' => sub {
            ok( !wait_on_message_or_timeout( $irc, 5 ) );
        };
    };

    describe 'when seeing an ibash URI' => sub {
        before sub {
            $irc->send_chan(
                '#happyman', 'PRIVMSG',
                '#happyman', 'http://www.ibash.de/zitat_3591.html'
            );
        };

        it 'does not react' => sub {
            ok( !wait_on_message_or_timeout( $irc, 5 ) );
        };
    };

    describe 'when seeing a URI' => sub {
        before sub {
            $irc->send_chan(
                '#happyman', 'PRIVMSG',
                '#happyman', 'http://chaosdorf.de/~mxey/'
            );
        };

        it 'sends the title to the channel' => sub {
            is( wait_on_message_or_timeout( $irc, 5 ), 'Index of /~mxey/' );
        };
    };

    describe 'when seeing a TwitterURI' => sub {
        before sub {
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                'https://twitter.com/BR3NDA/status/328753576220446720' );
        };

        it 'sends the author and message to the channel' => sub {
            is( wait_on_message_or_timeout( $irc, 5 ),
                'Tweet by @BR3NDA: Remembering that time I went to a Microsoft conference. all their swag clothing came in women\'s style. I had never seen that in open source.'
            );
        };
    };

};

runtests unless caller;
