package App::Happyman::Plugin::NickReply;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

sub on_message {
  my ($self, $sender, $body) = @_;

  if ($body eq $self->conn->nick) {
    $self->conn->send_message($sender);
  }
}

__PACKAGE__->meta->make_immutable();
