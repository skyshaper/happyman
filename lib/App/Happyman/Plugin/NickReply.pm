package App::Happyman::Plugin::NickReply;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent;

sub on_message {
    my ( $self, $msg ) = @_;
    
    if ( $msg->full_text eq $self->conn->nick ) {
        $self->_log( "Triggered by " . $msg->sender_nick );
    
        my $timer;
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->_log( "Replying to " . $msg->sender_nick );
            $self->conn->send_message_to_channel( $msg->sender_nick );
        };
    }
}

__PACKAGE__->meta->make_immutable();
