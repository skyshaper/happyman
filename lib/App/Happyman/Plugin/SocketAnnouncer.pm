package App::Happyman::Plugin::SocketAnnouncer;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::HTTPD;
use JSON;
use TryCatch;

has '_httpd' => (
    is      => 'ro',
    isa     => 'AnyEvent::HTTPD',
    builder => '_build_httpd',
);

sub _build_httpd {
    my ($self) = @_;
    my $httpd = AnyEvent::HTTPD->new( host => '127.0.0.1', port => 6666 );
    $httpd->reg_cb(
        '/plain' => sub {
            my ( $httpd, $req ) = @_;
            $self->conn->send_notice( $req->parm('message') );
            $req->respond( [ 200, 'OK', {}, 'sent' ] );
        },
        '/github' => sub {
            my ( $httpd, $req ) = @_;

            my $data;
            try {
                $data = decode_json( $req->parm('payload') );
            }
            catch {
                $req->respond(
                    [ 400, 'Bad Request', {}, 'JSON decode failed' ] );
                return;
            }

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
                $self->conn->send_notice($message);
            }

            $req->respond( [ 200, 'OK', {}, 'sent' ] );
        },
        '' => sub {
            my ( $httpd, $req ) = @_;
            $req->respond( [ 404, 'Not Found', {}, 'Not Found' ] );
        },
    );
    return $httpd;
}

__PACKAGE__->meta->make_immutable();
