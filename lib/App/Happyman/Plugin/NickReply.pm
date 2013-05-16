package App::Happyman::Plugin::NickReply;
use v5.16;
use Moose;
use Method::Signatures;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent;

method on_message (App::Happyman::Message $msg) {
    if ( $msg->full_text eq $self->conn->nick ) {
        $self->logger->log("Triggered by " . $msg->sender_nick);
        
        my $timer;
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->logger->log("Replying to " . $msg->sender_nick);
            $self->conn->send_message( $msg->sender_nick );
        };
    }
}

__PACKAGE__->meta->make_immutable();
