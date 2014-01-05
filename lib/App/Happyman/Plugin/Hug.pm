package App::Happyman::Plugin::Hug;
use v5.16;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use App::Happyman::Delay;

sub on_action {
    my ( $self, $action ) = @_;

    if ( $action->text eq 'hugs ' . $self->conn->nick ) {
        $self->_log( 'Hugged by ' . $action->sender_nick );

        delayed_randomly {
            $self->_log( 'Hugging ' . $action->sender_nick );
            $self->conn->send_action_to_channel(
                'hugs ' . $action->sender_nick );
        };
    }
    return;
}

__PACKAGE__->meta->make_immutable();
