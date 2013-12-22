package App::Happyman::Plugin::Hug;
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
        $timer = AE::timer rand(2), 0, sub {
            undef $timer;
            $self->_log( "Replying to " . $sender_nick );
            $action->();
            }
    }
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
