use v5.16;
use warnings;

use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::More tests => 13;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::RandomTopic');

my $happyman = App::Happyman::Connection->new(
    nick    => 'happyman',
    host    => 'localhost',
    port    => 6667,
    channel => '#happyman',
);
$happyman->add_plugin(App::Happyman::Plugin::RandomTopic->new(
    check_interval => 1,
    min_topic_age => 1,
));

my $irc = AnyEvent::IRC::Client->new();
my $cv  = AE::cv;
$irc->reg_cb(connect => $cv);
$irc->connect('localhost', 6667, { nick => 'HMTest' });
my (undef, $error) = $cv->recv();
if ($error) {
    BAIL_OUT("Failed to connect to test IRC server!: $error");
}

$irc->send_srv('JOIN', '#happyman');
$irc->reg_cb(channel_topic => sub { $cv->send(@_) });

my $timer;
for (1..10) {
    $cv = AE::cv;
    $timer = AE::timer(3, 0, $cv);
    my (undef, $topic, undef) = $cv->recv();
    ok($topic, "topic $_");
}


$happyman = App::Happyman::Connection->new(
    nick    => 'happyman',
    host    => 'localhost',
    port    => 6667,
    channel => '#happyman',
);
$happyman->add_plugin(App::Happyman::Plugin::RandomTopic->new());
$cv = AE::cv;
$timer = AE::timer(5, 0, $cv);
$cv->recv();

$cv = AE::cv;
$timer = AE::timer(5, 0, $cv);
$irc->send_chan('#happyman', 'PRIVMSG', '#happyman', '!topic');

my (undef, $topic, undef) = $cv->recv();
ok($topic, "!topic command");
