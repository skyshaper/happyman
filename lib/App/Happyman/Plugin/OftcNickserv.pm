package App::Happyman::Plugin::OftcNickserv;
use v5.16;
use Moose;
use Method::Signatures;

with 'App::Happyman::Plugin';

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

method on_registered ($payload) {
    $self->conn->send_private_message( 'NickServ',
        join( ' ', 'IDENTIFY', $self->password, $self->conn->nick ) );
}

__PACKAGE__->meta->make_immutable();
