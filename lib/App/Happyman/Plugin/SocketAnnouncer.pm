package App::Happyman::Plugin::SocketAnnouncer;
use v5.18;
use Moose;
use Method::Signatures;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use JSON::XS;
use Mojolicious::Lite;
use TryCatch;

has '_mojo' => (
    is      => 'ro',
    isa     => 'Mojo::Server::Daemon',
    builder => '_build_mojo',
);

method _build_mojo {
    post '/plain' => func($app) {
        $self->logger->log('Receiving /plain: ' . $app->param('message'));
        $self->conn->send_notice( $app->param('message') );
        $app->render(text => 'sent');
    };

    post '/github' => func($app) {
        $self->logger->debug($app->param('payload'));
        my $data = JSON::XS->new->decode( $app->param('payload') );

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
            $self->logger->log("Sending GitHub commit: $message");
            $self->conn->send_notice($message);
        }

        $app->render(status => 200, text => 'sent');
        return;
    },

    my $daemon = Mojo::Server::Daemon->new(app => app, listen => ['http://*:6666']);
    $daemon->start();
    return $daemon;
}

__PACKAGE__->meta->make_immutable();
