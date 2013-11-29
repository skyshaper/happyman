use v5.16;
use warnings;

use App::Happyman::Test;
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::PeekURI');

describe 'PeekURI' => sub {
    my $irc;

    before sub {
        $irc = make_test_client();
    };

    after sub {
        disconnect_and_wait($irc);
    };

    describe 'with default configuration' => sub {
        my $happyman;

        before sub {
            $happyman = make_happyman_with_plugin( 'PeekURI', {} );
        };

        after sub {
            $happyman->disconnect_and_wait();
        };

        describe 'when seeing a Wikipedia URI' => sub {
            before sub {
                $irc->send_chan(
                    '#happyman', 'PRIVMSG',
                    '#happyman', 'http://en.wikipedia.org/wiki/Perl'
                );
            };

            it 'sends the first paragraph to the channel' => sub {
                like(
                    wait_on_message_or_timeout( $irc, 5 ),
                    qr/Perl is a family of high-level, general-purpose, interpreted, dynamic programming languages/
                );
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
                is( wait_on_message_or_timeout( $irc, 5 ),
                    'Index of /~mxey/' );
            };
        };

        describe 'when seeing a broken URI' => sub {
            before sub {
                $irc->send_chan(
                    '#happyman', 'PRIVMSG',
                    '#happyman', 'http://doesnotexist.example.com/'
                );
            };

            it 'sends the error to the channel' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ),
                    "Couldn't connect: IO::Socket::INET: Bad hostname 'doesnotexist.example.com'"
                );
            };
        };

        describe 'when seeing a URI that leads to a 404' => sub {
            before sub {
                $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                    'http://chaosdorf.de/~mxey/nonexistingfile' );
            };

            it 'sends the error to the channel' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ), 'Not Found' );
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
        
        describe 'when seeing a Twitter URL with a picture' => sub {
            before sub {
                $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                    'https://twitter.com/ManuelaSchwesig/status/373757590347321344/photo/1' );
            };

            it 'sends the author and message to the channel' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ),
                    'Tweet by @ManuelaSchwesig: Gute Kitas anstatt Betreuungsgeld! Sonnige Grüsse aus Coburg ;-) http://t.co/0OSX2gzZBA'
                );
            };
        };
    };

    describe 'with incorrect Twitter authentication' => sub {
        my $happyman;

        before sub {
            $happyman = make_happyman_with_plugin( 'PeekURI',
                { twitter_consumer_key => 'foo', } );
        };

        after sub {
            $happyman->disconnect_and_wait();
        };

        describe 'when seeing a TwitterURI (status)' => sub {
            before sub {
                $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                    'https://twitter.com/BR3NDA/status/328753576220446720' );
            };

            it 'sends the error message to the channel' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ),
                    'Twitter: 32: Could not authenticate you'
                );
            };
        }; 
        
        describe 'when seeing a TwitterURI (statuses)' => sub {
            before sub {
                $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman',
                    'https://twitter.com/BR3NDA/statuses/328753576220446720' );
            };

            it 'sends the error message to the channel' => sub {
                is( wait_on_message_or_timeout( $irc, 5 ),
                    'Twitter: 32: Could not authenticate you'
                );
            };
        };
    };

};

runtests unless caller;
