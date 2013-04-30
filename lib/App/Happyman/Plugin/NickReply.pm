package App::Happyman::Plugin::NickReply;
use v5.16;
use Moose;
use Method::Signatures;

with 'App::Happyman::Plugin';

use AnyEvent;

method on_message (App::Happyman::Message $msg) {
    if ( $msg->full_text eq $self->conn->nick ) {
        my $timer;
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->conn->send_message( $msg->sender_nick );
        };
    }
}

__PACKAGE__->meta->make_immutable();
