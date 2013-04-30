package App::Happyman::Plugin::NickReply;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent;

sub on_message {
    my ( $self, $msg ) = @_;

    if ( $msg->full_text eq $self->conn->nick ) {
        my $timer;
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->conn->send_message( $msg->sender_nick );
        };
    }
}

__PACKAGE__->meta->make_immutable();
