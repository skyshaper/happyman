use v5.16;
use warnings;

use App::Happyman::Test;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::More tests => 23;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::RandomTopic');

my $happyman = make_happyman_with_plugin('App::Happyman::Plugin::RandomTopic', {
    check_interval => 1,
    min_topic_age => 1,
});
my $irc = make_test_client();

my ($cv, $timer);
$irc->reg_cb(channel_topic => sub { $cv->send(@_) });
my $previous_topic = '';
for (1..10) {
    $cv = AE::cv;
    $timer = AE::timer(3, 0, $cv);
    my (undef, $topic, undef) = $cv->recv();
    ok($topic, "topic $_ was set");
    isnt($topic, $previous_topic, "topic $_ is not equal to previous topic");
}

$happyman = make_happyman_with_plugin('App::Happyman::Plugin::RandomTopic', {});
$cv = AE::cv;
$timer = AE::timer(5, 0, $cv);
$cv->recv();

$cv = AE::cv;
$timer = AE::timer(5, 0, $cv);
$irc->send_chan('#happyman', 'PRIVMSG', '#happyman', '!topic');

my (undef, $topic, undef) = $cv->recv();
ok($topic, "!topic command");
