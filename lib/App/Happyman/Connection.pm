package App::Happyman::Connection;
use v5.18;
use Moose;
use namespace::autoclean;

use App::Happyman::Message;
use App::Happyman::Plugin;
use AnyEvent;
use AnyEvent::Strict;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(encode_ctcp prefix_nick);
use Data::Dumper::Concise;
use EV;
use Mojo::Log;
use TryCatch;

has [qw(nick host channel)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is      => 'ro',
    isa     => 'Int',
    default => 6667,
);

has [qw(ssl debug)] => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has _irc => (
    is      => 'ro',
    isa     => 'AnyEvent::IRC::Client',
    lazy    => 1,
    builder => '_build_irc',
);

has _plugins => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[App::Happyman::Plugin]',
    default => sub { [] },
);

has _stay_connected => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has _log => (
    is      => 'ro',
    isa     => 'Mojo::Log',
    builder => '_build_log',
    lazy    => 1,
    handles => { log => 'info', }
);

sub _build_log {
    my ($self) = @_;
    return Mojo::Log->new();
}

sub log_debug {
    my ( $self, $message ) = @_;
    $self->_log->debug($message) if $self->debug;
}

sub add_plugin {
    my ( $self, $plugin ) = @_;
    $plugin->conn($self);
    push $self->_plugins, $plugin;
}

sub _connect {
    my ($self) = @_;
    $self->_irc->enable_ssl() if $self->ssl;
    $self->_irc->connect(
        $self->host,
        $self->port,
        {   nick => $self->nick,
            user => $self->nick,
            real => $self->nick,
        }
    );

    $self->_irc->send_srv( 'JOIN', $self->channel );
}

sub _retry_connect {
    my ($self) = @_;
    my $w;
    $w = AE::timer 5, 0, sub {
        undef $w;
        $self->_log->info('Retrying connect');
        $self->_connect();
    };
}

sub _build_irc {
    my ($self) = @_;
    my $irc = AnyEvent::IRC::Client->new();

    $irc->reg_cb(
        publicmsg => sub {
            my ( $irc, $channel, $ircmsg ) = @_;
            my $sender    = prefix_nick( $ircmsg->{prefix} );
            my $full_text = $ircmsg->{params}->[1];

            my $msg
                = App::Happyman::Message->new( $self, $sender, $full_text );
            $self->_call_plugin_event_handlers( 'on_message', $msg );
        },
        connect => sub {
            my ( $irc, $err ) = @_;
            return if not $err;

            $self->_log->info('Connection failed');
            $self->_retry_connect();
        },
        disconnect => sub {
            $self->_log->info('Disconnected');
            $self->_retry_connect() if $self->_stay_connected;
        },
        registered => sub {
            $self->_log->info('Registered');
            $irc->enable_ping(60);
            $self->_call_plugin_event_handlers('on_registered');
        },
        channel_topic => sub {
            my ( $irc, $channel, $topic, $who ) = @_;
            $self->_log->info("Topic: $topic");
            $self->_call_plugin_event_handlers( 'on_topic', $topic );
        },
        debug_recv => sub {
            my ( $irc, $msg ) = @_;
            $self->_log->debug( 'In: ' . Dumper($msg) );
        },
        debug_send => sub {
            my ( $irc, @msg ) = @_;
            $self->_log->debug( 'Out: ' . Dumper( \@msg ) );
        },
    );

    return $irc;
}

sub BUILD {
    my ($self) = @_;
    $self->_connect();    # enforce construction
}

sub run_forever {
    my ($self) = @_;
    while (1) {
        try {
            AE::cv->recv();
        }
        catch {
            chomp;
            $self->send_notice_to_channel("Caught exception: $_");
            $self->_log->info("Caught exception: $_");
        }
    }
}

sub disconnect_and_wait {
    my ($self) = @_;
    my $cv = AE::cv;
    $self->_stay_connected(0);
    $self->_irc->reg_cb( disconnect => $cv );
    $self->_irc->send_srv('QUIT');
    $cv->recv();
    return;
}

sub _call_plugin_event_handlers {
    my ( $self, $name, $msg ) = @_;
    foreach my $plugin ( @{ $self->_plugins } ) {
        next unless $plugin->can($name);

        $self->log_debug("Starting: $plugin $name");
        $plugin->$name($msg);
        $self->log_debug("Done: $plugin $name");
    }
}

sub send_message_to_channel {
    my ( $self, $body ) = @_;
    $self->log_debug("Sending message to channel: $body");
    $self->_irc->send_long_message( 'utf-8', 0, 'PRIVMSG', $self->channel,
        $body );
}

sub send_notice_to_channel {
    my ( $self, $body ) = @_;
    $self->log_debug("Sending notice to channel: $body");
    $self->_irc->send_long_message( 'utf-8', 0, 'NOTICE', $self->channel,
        $body );
}

sub send_private_message {
    my ( $self, $nick, $body ) = @_;
    $self->log_debug("Sending privately to $nick: $body");
    $self->_irc->send_srv( 'PRIVMSG', $nick, $body );
}

sub is_nick_on_channel {
    my ( $self, $nick ) = @_;
    return defined $self->_irc->nick_modes( $self->channel, $nick );
}

sub set_topic {
    my ( $self, $topic ) = @_;
    $self->log_debug("Setting topic: $topic");
    $self->_irc->send_msg( 'TOPIC', $self->channel, $topic );
}

__PACKAGE__->meta->make_immutable();
