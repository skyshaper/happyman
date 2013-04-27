use v5.16;
use warnings;

use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(prefix_nick);
use Test::More tests => 5;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::NickReply');

my $happyman = App::Happyman::Connection->new(
    nick    => 'happyman',
    host    => 'localhost',
    port    => 6667,
    channel => '#happyman',
);
$happyman->add_plugin(App::Happyman::Plugin::NickReply->new());

my $irc = AnyEvent::IRC::Client->new();
my $cv  = AE::cv;
$irc->reg_cb(connect => $cv);
$irc->connect('localhost', 6667, { nick => 'HMTest' });
my (undef, $error) = $cv->recv();
if ($error) {
    BAIL_OUT("Failed to connect to test IRC server!: $error");
}

$irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'happyman');
$cv = AE::cv;
$irc->send_srv('JOIN', '#happyman');
$irc->reg_cb(publicmsg => $cv);
my $timer = AE::timer(5, 0, $cv);
my (undef, undef, $ircmsg) = $cv->recv();
if ($ircmsg) {
    my $sender    = prefix_nick($ircmsg->{prefix});
    my $full_text = $ircmsg->{params}->[1];
    is($sender,    'happyman',    'answer with correct nick');
    is($full_text, 'HMTest', 'answer with correct message');
}
else {
    fail('Did not receive answer within 5 seconds');
}

$irc->send_chan('#happyman', 'PRIVMSG', '#happyman', 'foobar');
$cv = AE::cv;
$irc->reg_cb(publicmsg => $cv);
$timer = AE::timer(5, 0, $cv);
(undef, undef, $ircmsg) = $cv->recv();
if ($ircmsg) {
    fail('received unwarranted answer');
}
else {
    ok('no unwarranted answer');
}