use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::RandomTopic');

describe 'The RandomTopic plugin' => sub {
    my $irc;

    before all => sub {
        diag 'Making test client';
        $irc = make_test_client();
    };

    after all => sub {
        diag 'Disconnecting test client';
        disconnect_and_wait($irc);
    };

    describe
        'with default settings when issued the !topic command with a 5 second timeout'
        => sub {
        my ( $happyman, $topic );

        before each => sub {
            diag 'making defaults happyman';
            $happyman = make_happyman_with_plugin(
                'App::Happyman::Plugin::RandomTopic', {} );
            $irc->send_chan( '#happyman', 'PRIVMSG', '#happyman', '!topic' );
            ( undef, undef, $topic, undef )
                = wait_on_event_or_timeout( $irc, 'channel_topic', 5 );
        };

        after each => sub {
            diag 'disconnecting defaults happyman';
            $happyman->disconnect_and_wait();
        };

        it 'should set a topic' => sub {
            ok($topic);
            }

        };

    describe 'with low topic age setting' => sub {
        my ( $previous_topic, $topic, $happyman );

        before all => sub {
            diag 'Making short time happyman';
            $happyman = make_happyman_with_plugin(
                'App::Happyman::Plugin::RandomTopic',
                {   check_interval => 0.2,
                    min_topic_age  => 3,
                }
            );
        };

        after all => sub {
            diag 'Disconnecting short time happyman';
            $happyman->disconnect_and_wait();
        };

        describe 'with a timeout of 5 seconds' => sub {
            before each => sub {
                diag 'Waiting on topic';
                $previous_topic = $topic;
                ( undef, undef, $topic, undef )
                    = wait_on_event_or_timeout( $irc, 'channel_topic', 5 );
            };

            it 'should set a topic' => sub {
                ok($topic);
            };

            it 'should set another topic' => sub {
                ok($topic);
            };

            it 'should set a another topic different from the previous one'
                => sub {
                isnt( $topic, $previous_topic );
                };
        };

        describe 'with the user setting a topic' => sub {
            before each => sub {
                $irc->send_msg( 'TOPIC', '#happyman', 'User topic' );
                ( undef, undef, $topic, undef )
                    = wait_on_event_or_timeout( $irc, 'channel_topic', 5 );
                if ( $topic ne 'User topic' ) {
                    BAIL_OUT('Failed to set user topic');
                }
            };

            it 'should not set a topic in 2 seconds' => sub {
                ( undef, undef, $topic, undef )
                    = wait_on_event_or_timeout( $irc, 'channel_topic', 2 );
                ok( !$topic );
            };

            it 'should set a topic in 5 seconds' => sub {
                ( undef, undef, $topic, undef )
                    = wait_on_event_or_timeout( $irc, 'channel_topic', 5 );
                ok($topic);
            };

        };
    };

};

runtests unless caller;

