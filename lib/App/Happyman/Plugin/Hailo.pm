package App::Happyman::Plugin::Hailo;
use 5.014;
use Moose;
use feature qw(say);

with 'App::Happyman::Plugin';

use Encode;
use Hailo;
use AnyEvent::Worker;

has '_hailo' => (
  is => 'ro',
  isa => 'AnyEvent::Worker',
  lazy => 1,
  builder => '_build_hailo',
);

sub _build_hailo {
  return AnyEvent::Worker->new({
      class => 'Hailo',
      args  => [brain => '/home/mxey/skyshaper/happyman/hailo.sqlite']
  });
}

sub on_message {
  my ($self, $sender, $body) = @_;

  $self->_hailo->do(learn => $body, sub {});
}

sub on_message_me {
  my ($self, $sender, $body) = @_;

  $self->_hailo->do(reply => $body, sub {
    my $msg = $@ || decode('utf-8', $_[1]);
    $self->conn->send_message("$sender: $msg");
  });
}

__PACKAGE__->meta->make_immutable();
