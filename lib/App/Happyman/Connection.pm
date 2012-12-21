package App::Happyman::Connection;
use v5.16;
use Moose;

use App::Happyman::Message;
use AnyEvent;
use AnyEvent::Impl::Perl;    # we depend on its exception behaviour
use AnyEvent::Strict;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(encode_ctcp prefix_nick);
use Coro;
use Try::Tiny;

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

sub add_plugin {
    my ($self, $plugin) = @_;

    $plugin->conn($self);
    push @{ $self->_plugins }, $plugin;
}

sub _connect {
    my ($self) = @_;

    $self->irc->enable_ssl() if $self->ssl;
    $self->irc->connect(
        $self->host,
        $self->port,
        {   nick => $self->nick,
            user => $self->nick,
            real => $self->nick,
        }
    );

    $self->irc->send_srv('JOIN', $self->channel);
}

sub _retry_connect {
    my ($self) = @_;

    my $w;
    $w = AE::timer 5, 0, sub {
        undef $w;
        say 'Retrying connect';
        $self->_connect();
    };
}

sub _build_irc {
    my ($self) = @_;

    my $irc = AnyEvent::IRC::Client->new();

    $irc->reg_cb(
        publicmsg => sub {
            my ($irc, $channel, $ircmsg) = @_;
            my $sender    = prefix_nick($ircmsg->{prefix});
            my $full_text = $ircmsg->{params}->[1];

            my $msg = App::Happyman::Message->new($self, $sender, $full_text);
            $self->_trigger_event('on_message', $msg);
        },
        connect => sub {
            my ($irc, $err) = @_;
            return if not $err;

            say 'Connection failed';
            $self->_retry_connect();
        },
        disconnect => sub {
            say 'Disconnected';
            $self->_retry_connect();
        },
        registered => sub {
            say 'Registered';
            $irc->enable_ping(60);
            $self->_trigger_event('on_registered');
        },
        channel_topic => sub {
            my ($irc, $channel, $topic, $who) = @_;
            say "Topic: $topic";
            $self->_trigger_event('on_topic', $topic);
        }
    );

    return $irc;
}

sub BUILD {
    my ($self) = @_;

    $self->_connect();    # enforce construction
}

sub run {
    my ($self) = @_;

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

sub _trigger_event {
    my ($self, $name, $msg) = @_;

    foreach my $plugin (@{ $self->_plugins }) {
        next unless $plugin->can($name);

        async {
            say "Starting: $plugin $name";
            $plugin->$name($msg);
            say "Done: $plugin $name";
        };
    }
}

sub send_message {
    my ($self, $body) = @_;

    $self->irc->send_long_message('utf-8', 0, 'PRIVMSG', $self->channel,
        $body);
}

sub send_notice {
    my ($self, $body) = @_;

    $self->irc->send_long_message('utf-8', 0, 'NOTICE', $self->channel,
        $body);
}

sub send_private_message {
    my ($self, $nick, $body) = @_;

    $self->irc->send_srv('PRIVMSG', $nick, $body);
}

sub nick_exists {
    my ($self, $nick) = @_;

    return defined $self->irc->nick_modes($self->channel, $nick);
}

sub set_topic {
    my ($self, $topic) = @_;
    $self->irc->send_msg('TOPIC', $self->channel, $topic);
}


__PACKAGE__->meta->make_immutable();
