package App::Happyman::Plugin::NickReply;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use Coro::AnyEvent;

sub on_message {
    my ( $self, $msg ) = @_;
    
    if ($msg->full_text eq $self->conn->nick) {
        Coro::AnyEvent::sleep rand(2);
        $self->conn->send_message($msg->sender_nick);
    }
}

__PACKAGE__->meta->make_immutable();
