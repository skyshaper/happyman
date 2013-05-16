package App::Happyman::Connection;
use v5.16;
use Moose;
use Method::Signatures;
use namespace::autoclean;

use App::Happyman::Message;
use App::Happyman::Plugin;
use AnyEvent;
use AnyEvent::Strict;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(encode_ctcp prefix_nick);
use EV;
use Log::Dispatchouli;
use TryCatch;

has 'irc' => (
    is      => 'ro',
    isa     => 'AnyEvent::IRC::Client',
    lazy    => 1,
    builder => '_build_irc',
    handles => { send => 'send_srv', },
);

has 'nick' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => 6667,
);

has 'ssl' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has 'channel' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has '_plugins' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[App::Happyman::Plugin]',
    default => sub { [] },
);

has '_stay_connected' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has _logger => (
    is      => 'ro',
    isa     => 'Log::Dispatchouli',
    builder => '_build_logger',
);

method _build_logger {
    return Log::Dispatchouli->new({
      ident     => 'happyman',
      facility  => 'daemon',
      to_stdout => 1,
      debug     => 1,
    });
}

method add_plugin (App::Happyman::Plugin $plugin) {
    $plugin->conn($self);
    push $self->_plugins, $plugin;
}

method _connect {
    $self->irc->enable_ssl() if $self->ssl;
    $self->irc->connect(
        $self->host,
        $self->port,
        {   nick => $self->nick,
            user => $self->nick,
            real => $self->nick,
        }
    );

    $self->irc->send_srv( 'JOIN', $self->channel );
}

method _retry_connect {
    my $w;
    $w = AE::timer 5, 0, sub {
        undef $w;
        say 'Retrying connect';
        $self->_connect();
    };
}

method _build_irc {
    my $irc = AnyEvent::IRC::Client->new();

    $irc->reg_cb(
        publicmsg => sub {
            my ( $irc, $channel, $ircmsg ) = @_;
            my $sender    = prefix_nick( $ircmsg->{prefix} );
            my $full_text = $ircmsg->{params}->[1];

            my $msg
                = App::Happyman::Message->new( $self, $sender, $full_text );
            $self->_trigger_event( 'on_message', $msg );
        },
        connect => sub {
            my ( $irc, $err ) = @_;
            return if not $err;

            say 'Connection failed';
            $self->_retry_connect();
        },
        disconnect => sub {
            say 'Disconnected';
            $self->_retry_connect() if $self->_stay_connected;
        },
        registered => sub {
            say 'Registered';
            $irc->enable_ping(60);
            $self->_trigger_event('on_registered');
        },
        channel_topic => sub {
            my ( $irc, $channel, $topic, $who ) = @_;
            say "Topic: $topic";
            $self->_trigger_event( 'on_topic', $topic );
        }
    );

    return $irc;
}

method BUILD (...) {
    $self->_connect();    # enforce construction
}

method run {
    while (1) {
        try {
            AE::cv->recv();
        }
        catch {
            chomp;
            $self->send_notice("Caught exception: $_");
            STDERR->say("Caught exception: $_");
        }
    }
}

method disconnect_and_wait {
    my $cv = AE::cv;
    $self->_stay_connected(0);
    $self->irc->reg_cb( disconnect => $cv );
    $self->irc->send_srv('QUIT');
    $cv->recv();
    return;
}

method _trigger_event (Str $name, $msg = undef) {
    foreach my $plugin ( @{ $self->_plugins } ) {
        next unless $plugin->can($name);

        say "Starting: $plugin $name";
        $plugin->$name($msg);
        say "Done: $plugin $name";
    }
}

method send_message (Str $body) {
    $self->irc->send_long_message( 'utf-8', 0, 'PRIVMSG', $self->channel,
        $body );
}

method send_notice (Str $body) {
    $self->irc->send_long_message( 'utf-8', 0, 'NOTICE', $self->channel,
        $body );
}

method send_private_message (Str $nick, Str $body) {
    $self->irc->send_srv( 'PRIVMSG', $nick, $body );
}

method nick_exists (Str $nick) {
    return defined $self->irc->nick_modes( $self->channel, $nick );
}

method set_topic (Str $topic) {
    $self->irc->send_msg( 'TOPIC', $self->channel, $topic );
}

__PACKAGE__->meta->make_immutable();
