package App::Happyman::Plugin::NickReply;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use Coro::AnyEvent;

sub on_message {
    my ( $self, $sender, $body ) = @_;
    return if $body ne $self->conn->nick;

    Coro::AnyEvent::sleep rand(2);
    $self->conn->send_message($sender);
}

__PACKAGE__->meta->make_immutable();
