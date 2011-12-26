package App::Happyman::Plugin::SocketAnnouncer;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::HTTPD;

has '_httpd' => (
    is => 'ro',
    isa => 'AnyEvent::HTTPD',
    builder => '_build_httpd',
);

sub _build_httpd {
    my ($self) = @_;
    my $httpd = AnyEvent::HTTPD->new(port => 6666);
    $httpd->reg_cb(
        '/plain' => sub {
            my ($httpd, $req) = @_;
            $self->conn->send_notice( $req->parm('message') );
            $req->respond([200, 'OK', {}, 'sent']);
        },
        '' => sub {
            my ($httpd, $req) = @_;
            $req->respond([404, 'Not Found', {}, 'Not Found']);
        },
    );
    return $httpd;
}

__PACKAGE__->meta->make_immutable();
