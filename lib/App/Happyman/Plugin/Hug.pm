package App::Happyman::Plugin::Hug;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent;

sub on_action {
    my ( $self, $action ) = @_;
    
    if ( $action->text eq 'hugs ' . $self->conn->nick ) {
        $self->_log( 'Hugged by ' . $action->sender_nick );
    
        my $timer;
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->_log( 'Hugging ' . $action->sender_nick );
            $self->conn->send_action_to_channel(
                'hugs ' . $action->sender_nick );
        };
    }
}

__PACKAGE__->meta->make_immutable();
