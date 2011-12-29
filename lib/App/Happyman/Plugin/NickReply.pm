package App::Happyman::Plugin::NickReply;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

sub on_message {
  my ($self, $sender, $body) = @_;

  if (($sender ne $body) && $self->conn->nick_exists($body)) {
    $self->conn->send_message($sender);
  }
}

__PACKAGE__->meta->make_immutable();
