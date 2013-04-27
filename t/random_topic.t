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
        $irc->disconnect();
    };
    
    describe 'with default settings when issued the !topic command with a 5 second timeout' => sub {
        my ($happyman, $topic);
        
        before each => sub {
            diag 'making defaults happyman';
            $happyman = make_happyman_with_plugin('App::Happyman::Plugin::RandomTopic', {});
            $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', '!topic');
            (undef, undef, $topic, undef) = wait_on_event_or_timeout($irc, 'channel_topic', 5);
        };
        
        after each => sub {
            diag 'disconnecting defaults happyman';
            $happyman->disconnect_and_wait();
        };
        
        it 'should set a topic' => sub {
            ok($topic);
        }
        
    };
    
    describe 'with short time settings with a timeout of 10 seconds' => sub {
        my ($previous_topic, $topic, $happyman);
        
        before all => sub {
            diag 'Making short time happyman';
            $happyman = make_happyman_with_plugin('App::Happyman::Plugin::RandomTopic', {
                check_interval => 1,
                min_topic_age => 1,
            });
        };
        
        after all => sub {
            diag 'Disconnecting short time happyman';
            $happyman->disconnect_and_wait();
        };
        
        before each => sub {
            diag 'Waiting on topic';
            $previous_topic = $topic;
            (undef, undef, $topic, undef) = wait_on_event_or_timeout($irc, 'channel_topic', 10);
        };
        
        it 'should set a topic' => sub {        
            ok($topic);
        };

        it 'should set another topic' => sub {
            ok($topic);
        };
        
        it 'should set a another topic different from the previous one' => sub {
            isnt($topic, $previous_topic);
        };
    };
    
};

runtests unless caller;



