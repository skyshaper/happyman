use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::HTTPD;
use MIME::Base64;
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::SATQ');

describe 'App::Happyman::Plugin::SATQ' => sub {
    my $happyman;
    my $irc;
    my $httpd;
    my $http_request_cv;
    
    before all => sub {
        $httpd = AnyEvent::HTTPD->new(host => '127.0.0.1', port => 7777);
        $httpd->reg_cb(
            '/quotes' => sub {
                my (undef, $req) = @_;
                $req->respond([ 200, 'OK', {Location => 'http://example.com'}, '' ]);
                $http_request_cv->send($req);
            },
        );
    };
    
    before each => sub {
        $happyman = make_happyman_with_plugin('App::Happyman::Plugin::SATQ', {
            uri => 'http://localhost:7777/quotes',
            user => 'happyman',
            password => 'happypass',
        });
        $irc = make_test_client();
        $http_request_cv = AE::cv;
    };
    
    after each => sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };
    
    describe 'when 20 messages have been received' => sub {
        before sub {
            for (1..20) {
                $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'Hello World');
            }
            async_sleep(3);
        };
        
        describe 'when issued the !quote command' => sub {
            before sub {
                $irc->send_chan('#happyman', 'PRIVMSG', '#happyman', '!quote');
            };
            
            it 'posts the last 10 messages to SATQ' => sub {
                my $req = $http_request_cv->recv();
                my $raw_quote = $req->parm('quote[raw_quote]');
                is($raw_quote, join("\n", ('<HMTest> Hello World') x 10));
            };
        
            it 'uses the configured credentials' => sub {
                my $req = $http_request_cv->recv();
                use Data::Dumper; print Dumper $req->headers;
                is($req->headers->{authorization}, 'Basic ' . encode_base64('happyman:happypass', ''))
            };
            
            it 'posts the quote link to the channel' => sub {
                is(wait_on_message_or_timeout($irc, 5), 'HMTest: http://example.com');
            },
        };
    };
    
    
    
};

runtests unless caller;
