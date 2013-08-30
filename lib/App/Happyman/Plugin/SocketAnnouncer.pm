package App::Happyman::Plugin::SocketAnnouncer;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use Data::Dumper::Concise;
use Encode;
use Mojo::JSON;
use Mojolicious::Lite;
use TryCatch;

has _mojo => (
    is      => 'ro',
    isa     => 'Mojo::Server::Daemon',
    builder => '_build_mojo',
);

sub _build_mojo {
    my ($self) = @_;
    post '/plain' => sub {
        my ($app) = @_;
        $self->_log( 'Receiving /plain: ' . $app->param('message') );
        $self->conn->send_notice_to_channel( $app->param('message') );
        $app->render( text => 'sent' );
    };

    post '/github' => sub {
        my ($app) = @_;

        # Mojolicous decodes all request parameters, but Mojo::JSON only accepts bytes
        my $payload_string = $app->param('payload');
        my $payload_bytes  = encode('utf-8', $payload_string);

        my $json = Mojo::JSON->new;
        my $data = $json->decode( $payload_bytes );

        foreach my $commit ( @{ $data->{commits} } ) {
            my $message = sprintf(
                "%s/%s (%s): %s - %s: %s\n",
                $data->{repository}->{owner}->{name},
                $data->{repository}->{name},
                ( split( qr{/}, $data->{ref} ) )[-1],
                $commit->{author}->{name},
                substr( $commit->{id}, 0, 8 ),
                ( split( qr{\n}, $commit->{message} ) )[0],
            );
            $self->_log("Sending GitHub commit: $message");
            $self->conn->send_notice_to_channel($message);
        }

        $app->render( status => 200, text => 'sent' );
        return;
    };

    post '/heroku' => sub {
        my ($app) = @_;

        # $self->_log(['Receiving /heroku: %s', $app->param]);
        my $message = sprintf( '%s deployed %s to %s',
            $app->param('user'), $app->param('head'), $app->param('url') );
        $self->_log("Sending Heroku message: $message");
        $self->conn->send_notice_to_channel($message);
        $app->render( status => 200, text => 'sent' );
    };

    my $daemon = Mojo::Server::Daemon->new(
        app    => app,
        listen => ['http://localhost:6666']
    );
    $daemon->start();
    return $daemon;
}

__PACKAGE__->meta->make_immutable();
