package App::Happyman::Plugin::NickReply;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent;

sub _do_nick_reply {
    my ( $self, $text, $needed_text, $sender_nick, $action ) = @_;

    $text =~ s/^\s+|\s+$//g;

    if ( $text eq $needed_text ) {
        $self->_log( "Triggered by " . $sender_nick );

        my $timer;
        $timer = AE::timer
            rand(2), 0, sub {
            undef $timer;
            $self->_log( "Replying to " . $sender_nick );
            $action->();
            }
    }
}

sub on_message {
    my ( $self, $msg ) = @_;

    $self->_do_nick_reply(
        $msg->full_text,
        $self->conn->nick,
        $msg->sender_nick,
        sub {
            $self->conn->send_message_to_channel( $msg->sender_nick );
        }
    );
}

sub on_action {
    my ( $self, $action ) = @_;

    $self->_do_nick_reply(
        $action->text,
        "hugs " . $self->conn->nick,
        $action->sender_nick,
        sub {
            $self->conn->send_action_to_channel(
                "hugs " . $action->sender_nick );
        }
    );
}

__PACKAGE__->meta->make_immutable();
