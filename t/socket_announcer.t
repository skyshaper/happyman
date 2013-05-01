use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Data::Handle;
use File::Slurp;
use LWP::Protocol::AnyEvent::http;
use LWP::Simple;
use Test::Deep;
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::SocketAnnouncer');

describe 'The SocketAnnouncer plugin' => sub {
    my ( $irc, $lwp, $happyman );

    before all => sub {
        $irc      = make_test_client();
        $happyman = make_happyman_with_plugin(
            'App::Happyman::Plugin::SocketAnnouncer', {} );
        $lwp = LWP::UserAgent->new();
    };

    after all => sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    it 'should accept HTTP requests on its socket' => sub {
        my $response = $lwp->head('http://localhost:6666/');
        is( $response->status_line, '404 Not Found' );
    };

    describe 'when sent a plain message' => sub {
        before sub {
            $lwp->post(
                'http://localhost:6666/plain',
                { message => 'Hello World', }
            );
        };

        it 'should send the message to the channel' => sub {
            is( wait_on_message_or_timeout( $irc, 5 ), 'Hello World' );
        };
    };

    describe 'when sent an example GitHub payload' => sub {

        before sub {
            my $github_payload = read_file( Data::Handle->new(__PACKAGE__) );
            $lwp->post(
                'http://localhost:6666/github',
                { payload => $github_payload }
            );
        };

        it 'should send the 3 commits to the channel' => sub {
            my (@lines);
            $irc->reg_cb(
                publicmsg => sub {
                    my ( undef, undef, $ircmsg ) = @_;
                    push @lines, $ircmsg->{params}->[1];
                }
            );
            my $cv = AE::cv;
            my $timer = AE::timer( 5, 0, $cv );
            $cv->recv();

            my @expected = (
                'octokitty/testing (master): Garen Torikian - c441029c: Test',
                'octokitty/testing (master): Garen Torikian - 36c5f224: This is me testing the windows client.',
                'octokitty/testing (master): Garen Torikian - 1481a2de: Rename madame-bovary.txt to words/madame-bovary.txt',
            );

            cmp_deeply( \@lines, \@expected );
        };
    };

};

runtests unless caller;

# GitHub example payload follows
__DATA__
{
   "after":"1481a2de7b2a7d02428ad93446ab166be7793fbb",
   "before":"17c497ccc7cca9c2f735aa07e9e3813060ce9a6a",
   "commits":[
      {
         "added":[

         ],
         "author":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "committer":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "distinct":true,
         "id":"c441029cf673f84c8b7db52d0a5944ee5c52ff89",
         "message":"Test",
         "modified":[
            "README.md"
         ],
         "removed":[

         ],
         "timestamp":"2013-02-22T13:50:07-08:00",
         "url":"https://github.com/octokitty/testing/commit/c441029cf673f84c8b7db52d0a5944ee5c52ff89"
      },
      {
         "added":[

         ],
         "author":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "committer":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "distinct":true,
         "id":"36c5f2243ed24de58284a96f2a643bed8c028658",
         "message":"This is me testing the windows client.",
         "modified":[
            "README.md"
         ],
         "removed":[

         ],
         "timestamp":"2013-02-22T14:07:13-08:00",
         "url":"https://github.com/octokitty/testing/commit/36c5f2243ed24de58284a96f2a643bed8c028658"
      },
      {
         "added":[
            "words/madame-bovary.txt"
         ],
         "author":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "committer":{
            "email":"lolwut@noway.biz",
            "name":"Garen Torikian",
            "username":"octokitty"
         },
         "distinct":true,
         "id":"1481a2de7b2a7d02428ad93446ab166be7793fbb",
         "message":"Rename madame-bovary.txt to words/madame-bovary.txt",
         "modified":[

         ],
         "removed":[
            "madame-bovary.txt"
         ],
         "timestamp":"2013-03-12T08:14:29-07:00",
         "url":"https://github.com/octokitty/testing/commit/1481a2de7b2a7d02428ad93446ab166be7793fbb"
      }
   ],
   "compare":"https://github.com/octokitty/testing/compare/17c497ccc7cc...1481a2de7b2a",
   "created":false,
   "deleted":false,
   "forced":false,
   "head_commit":{
      "added":[
         "words/madame-bovary.txt"
      ],
      "author":{
         "email":"lolwut@noway.biz",
         "name":"Garen Torikian",
         "username":"octokitty"
      },
      "committer":{
         "email":"lolwut@noway.biz",
         "name":"Garen Torikian",
         "username":"octokitty"
      },
      "distinct":true,
      "id":"1481a2de7b2a7d02428ad93446ab166be7793fbb",
      "message":"Rename madame-bovary.txt to words/madame-bovary.txt",
      "modified":[

      ],
      "removed":[
         "madame-bovary.txt"
      ],
      "timestamp":"2013-03-12T08:14:29-07:00",
      "url":"https://github.com/octokitty/testing/commit/1481a2de7b2a7d02428ad93446ab166be7793fbb"
   },
   "pusher":{
      "name":"none"
   },
   "ref":"refs/heads/master",
   "repository":{
      "created_at":1332977768,
      "description":"",
      "fork":false,
      "forks":0,
      "has_downloads":true,
      "has_issues":true,
      "has_wiki":true,
      "homepage":"",
      "id":3860742,
      "language":"Ruby",
      "master_branch":"master",
      "name":"testing",
      "open_issues":2,
      "owner":{
         "email":"lolwut@noway.biz",
         "name":"octokitty"
      },
      "private":false,
      "pushed_at":1363295520,
      "size":2156,
      "stargazers":1,
      "url":"https://github.com/octokitty/testing",
      "watchers":1
   }
}
