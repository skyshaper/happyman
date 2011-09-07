package App::Happyman::Connection;
use Moose;

use AnyEvent;
use AnyEvent::Impl::Perl; # we depend on its exception behaviour
use AnyEvent::Strict;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw(encode_ctcp prefix_nick);
use Try::Tiny;

has 'irc' => (
  is         => 'ro',
  isa        => 'AnyEvent::IRC::Client',
  lazy       => 1,
  builder    => '_build_irc',
  handles    => {
    send => 'send_srv',
  },
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
  is       => 'ro',
  isa      => 'Int',
  default  => 6667,
);

has 'ssl' => (
  is       => 'ro',
  isa      => 'Bool',
  default  => 0,
);

has 'channel' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has '_plugins' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[App::Happyman::Plugin]',
  default  => sub { [] },
);

sub add_plugin {
  my ($self, $plugin) = @_;

  $plugin->conn($self);
  push @{ $self->_plugins }, $plugin;
}

sub _build_irc {
  my ($self) = @_;

  my $irc = AnyEvent::IRC::Client->new();

  $irc->reg_cb(publicmsg => sub {
    my ($irc, $channel, $ircmsg) = @_;
    my $sender = prefix_nick( $ircmsg->{prefix} );
    my $text = $ircmsg->{params}->[1];

    if ($text =~ /^(\w+)[:,]\s+(.+)$/) {
      # for some weird reason, without stringification the value turns to undef
      # at some point
      $self->_trigger_event('on_message', $sender, "$2");

      if ($1 eq $self->nick) {
        $self->_trigger_event('on_message_me', $sender, "$2");
      }
    }
    else {
      $self->_trigger_event('on_message', $sender, $text);
    }
  });

  $irc->enable_ssl() if $self->ssl;
  $irc->connect($self->host, $self->port, {
    nick => $self->nick,
    user => $self->nick,
    real => $self->nick,
  });

  $irc->send_srv('JOIN', $self->channel);
  return $irc;
}

sub BUILD {
  my ($self) = @_;

  $self->irc(); # enforce construction
}

sub run {
  my ($self) = @_;

  while (1) {
    try {
      AnyEvent->condvar->recv();
    }
    catch {
      chomp;
      STDERR->say("Caught exception: $_");
    }
  }
}

sub _trigger_event {
  my ($self, $name, $sender, $channel, $body) = @_;

  foreach my $plugin (@{ $self->_plugins }) {
    $plugin->$name($sender, $channel, $body) if $plugin->can($name);
  }
}

sub send_message {
  my ($self, $body) = @_;

  $self->irc->send_long_message('utf-8', 0, 'PRIVMSG', $self->channel, $body);
}

sub send_notice {
  my ($self, $body) = @_;

  $self->irc->send_long_message('utf-8', 0, 'NOTICE', $self->channel, $body);
}

__PACKAGE__->meta->make_immutable();
