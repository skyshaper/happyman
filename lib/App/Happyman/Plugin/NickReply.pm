package App::Happyman::Plugin::NickReply;
use v5.14;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use App::Happyman::Delay;

sub on_message {
    my ( $self, $msg ) = @_;

    if ( $msg->full_text eq $self->conn->nick ) {
        $self->_log( "Triggered by " . $msg->sender_nick );

        delayed_randomly {
            $self->_log( "Replying to " . $msg->sender_nick );
            $self->conn->send_message_to_channel( $msg->sender_nick );
        };
    }
    return;
}

__PACKAGE__->meta->make_immutable();
