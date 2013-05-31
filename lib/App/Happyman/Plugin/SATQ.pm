package App::Happyman::Plugin::SATQ;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use Mojo::UserAgent;
use MIME::Base64;

has '_buffer' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has [qw(uri user password)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub on_message {
    my ( $self, $msg ) = @_;
    if ( $msg->full_text =~ /^\!quote\s*$/ ) {
        my $authorization = 'Basic '
            . encode_base64( $self->user . ':' . $self->password, '' );
        my $headers = { Authorization => $authorization };
        my $form
            = { 'quote[raw_quote]' => join( "\n", @{ $self->_buffer } ) };
        $self->logger->log_debug( [ 'Posting quote: %s', $form ] );

        $self->_ua->post(
            $self->uri,
            $headers,
            form => $form,
            sub {
                my ( undef, $tx ) = @_;
                if ( $tx->error ) {
                    $self->logger->log( $tx->error );
                    $msg->reply( $tx->error );
                }
                $self->logger->log( $tx->res->headers->location
                        || $tx->res->code );
                $msg->reply( $tx->res->headers->location || $tx->res->code );
            }
        );
    }

    my $line = sprintf( '<%s> %s', $msg->sender_nick, $msg->full_text );
    if ( @{ $self->_buffer } >= 10 ) {
        shift $self->_buffer;
    }
    $self->logger->log_debug("Buffering: $line");
    push $self->_buffer, $line;
}

__PACKAGE__->meta->make_immutable();
