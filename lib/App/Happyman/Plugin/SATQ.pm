package App::Happyman::Plugin::SATQ;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use Data::Dumper::Concise;
use Encode;
use Mojo::UserAgent;
use MIME::Base64;

has _buffer => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has [qw(uri user password)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub _push_line_to_buffer {
    my ( $self, $line ) = @_;
    if ( @{ $self->_buffer } >= 10 ) {
        shift $self->_buffer;
    }
    $self->_log_debug("Buffering: $line");
    push $self->_buffer, $line;
}

sub _upload_quote_to_satq {
    my ( $self, $quote_command_message ) = @_;
    my $authorization
        = 'Basic ' . encode_base64( $self->user . ':' . $self->password, '' );
    my $headers = { Authorization => $authorization };
    my $form
        = { 'quote[raw_quote]' =>
            decode( 'utf-8', join( "\n", @{ $self->_buffer } ) ) };
    $self->_log_debug( 'Posting quote: ' . Dumper($form) );

    $self->_ua->post(
        $self->uri,
        $headers,
        form => $form,
        sub {
            my ( undef, $tx ) = @_;
            if ( $tx->error ) {
                $self->_log( $tx->error );
                $quote_command_message->reply_on_channel( $tx->error );
            }
            $self->_log( $tx->res->headers->location || $tx->res->code );
            $quote_command_message->reply_on_channel(
                $tx->res->headers->location || $tx->res->code );
        }
    );
}

sub on_message {
    my ( $self, $msg ) = @_;
    if ( $msg->full_text =~ /^\!quote\s*$/ ) {
        $self->_upload_quote_to_satq($msg);
    }

    $self->_push_line_to_buffer(
        sprintf( '<%s> %s', $msg->sender_nick, $msg->full_text ) );

}

sub on_action {
    my ( $self, $action ) = @_;
    $self->_push_line_to_buffer(
        sprintf( '* %s %s', $action->sender_nick, $action->text ) );
}

__PACKAGE__->meta->make_immutable();
