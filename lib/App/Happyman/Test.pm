package App::Happyman::Test;
use v5.16;
use warnings;
use Method::Signatures;


use parent 'Exporter';
our @EXPORT
    = qw(make_happyman_with_plugin make_test_client wait_on_event_or_timeout disconnect_and_wait wait_on_message_or_timeout load_local_config async_sleep);

use AnyEvent;
use Config::INI::Reader;

func make_happyman_with_plugin (Str $plugin_name, HashRef $plugin_params) {
    my $happyman = App::Happyman::Connection->new(
        nick    => 'happyman',
        host    => 'localhost',
        port    => 6667,
        channel => '#happyman',
        debug   => 1,
    );
    my $plugin = $plugin_name->new($plugin_params);
    $happyman->add_plugin($plugin);
    return $happyman;
}

func make_test_client ($nick = 'HMTest') {
    my $irc = AnyEvent::IRC::Client->new();
    my $cv  = AE::cv;
    $irc->reg_cb( connect => $cv );
    $irc->connect( 'localhost', 6667, { nick => $nick } );
    my ( undef, $error ) = $cv->recv();
    if ($error) {
        BAIL_OUT("Failed to connect to test IRC server!: $error");
    }
    $irc->send_srv( 'JOIN', '#happyman' );
    return $irc;
}

func wait_on_event_or_timeout (AnyEvent::IRC::Client $irc, Str $event, Num $timeout) {
    my $cv = AE::cv;
    $irc->reg_cb( $event => $cv );
    my $timer = AE::timer( $timeout, 0, $cv );
    return $cv->recv();
}

func wait_on_message_or_timeout (AnyEvent::IRC::Client $irc, Num $timeout) {
    my ( undef, undef, $ircmsg )
        = wait_on_event_or_timeout( $irc, 'publicmsg', $timeout );
    return $ircmsg ? $ircmsg->{params}->[1] : undef;
}

func disconnect_and_wait (AnyEvent::IRC::Client $irc) {
    my $cv = AE::cv;
    $irc->reg_cb( disconnect => $cv );
    $irc->send_srv('QUIT');
    $cv->recv();
    return;
}

func load_local_config {
    return Config::INI::Reader->read_file('happyman.conf');
}

func async_sleep (Num $seconds) {
    my $cv = AE::cv;
    my $timer = AE::timer $seconds, 0, $cv;
    $cv->recv();
    return;
}

1;
