package App::Happyman::Test;
use v5.16;
use warnings;

use parent 'Test::Builder::Module';
our @EXPORT
    = qw(make_happyman_with_plugin make_test_client wait_on_event_or_timeout disconnect_and_wait wait_on_message_or_timeout wait_on_action_or_timeout load_local_config async_sleep);

use AnyEvent;
use AnyEvent::IRC::Client;
use File::Slurp;
use Mojo::JSON;

sub load_local_config {
    my $json = Mojo::JSON->new;
    my $conf = $json->decode( scalar read_file('happyman.conf') );
    if (!$conf) {
        __PACKAGE__->builder->BAIL_OUT('Failed to load local happyman.conf');
    }
    
    return $conf;
}

sub make_happyman_with_plugin {
    my ( $plugin_name, $plugin_params ) = @_;
    my $conf = load_local_config();
    my $happyman = App::Happyman::Connection->new(
        nick    => $conf->{connection}{nick} // 'happyman',
        host    => $conf->{connection}{host} // 'localhost',
        port    => $conf->{connection}{port} // 6667,
        channel => $conf->{connection}{channel} // '#happyman',
        debug   => $ENV{HAPPYMAN_TEST_DEBUG} ? 1 : 0,
    );
    $happyman->load_plugin( $plugin_name, $plugin_params );
    return $happyman;
}

sub make_test_client {
    my ($nick) = @_;
    my $conf = load_local_config();
    $nick ||= 'HMTest';
    my $irc = AnyEvent::IRC::Client->new();
    my $cv  = AE::cv;
    $irc->reg_cb( connect => $cv );
    $irc->connect( $conf->{connection}{host} // 'localhost',
                   $conf->{connection}{port} // 6667,
                   { nick => $nick } );
    my ( undef, $error ) = $cv->recv();
    if ($error) {
        __PACKAGE__->builder->BAIL_OUT(
            "Failed to connect to test IRC server!: $error");
    }
    $irc->send_srv( 'JOIN', '#happyman' );
    return $irc;
}

sub wait_on_event_or_timeout {
    my ( $irc, $event, $timeout ) = @_;
    $timeout //= 10;
    my $cv = AE::cv;
    $irc->reg_cb( $event => $cv );
    my $timer = AE::timer( $timeout, 0, $cv );
    return $cv->recv();
}

sub wait_on_message_or_timeout {
    my ( $irc, $timeout ) = @_;
    my ( undef, undef, $ircmsg )
        = wait_on_event_or_timeout( $irc, 'publicmsg', $timeout );
    return $ircmsg ? $ircmsg->{params}->[1] : undef;
}

sub wait_on_action_or_timeout {
    my ( $irc, $timeout ) = @_;
    my ( undef, undef, undef, $msg )
        = wait_on_event_or_timeout( $irc, 'ctcp_action', $timeout );
    return $msg;
}

sub disconnect_and_wait {
    my ( $irc, $timeout ) = @_;
    my $cv = AE::cv;
    $irc->reg_cb( disconnect => $cv );
    $irc->send_srv('QUIT');
    $cv->recv();
    return;
}

sub async_sleep {
    my ($seconds) = @_;
    my $cv = AE::cv;
    my $timer = AE::timer $seconds, 0, $cv;
    $cv->recv();
    return;
}

1;
