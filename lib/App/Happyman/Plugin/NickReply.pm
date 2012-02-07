package App::Happyman::Plugin::NickReply;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent;

sub on_message {
  my ($self, $sender, $body) = @_;

  if ($body eq $self->conn->nick) {
    my $w;
    $w = AE::timer(rand(2), 0, sub { 
      undef $w; 
      $self->conn->send_message($sender);
    });
  }
}

__PACKAGE__->meta->make_immutable();
