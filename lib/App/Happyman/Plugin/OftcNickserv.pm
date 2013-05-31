package App::Happyman::Plugin::OftcNickserv;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub on_registered {
    my ($self, $payload) = @_;
    $self->logger->log('Claiming my nick from NickServ');
    $self->conn->send_private_message( 'NickServ',
        join( ' ', 'IDENTIFY', $self->password, $self->conn->nick ) );
}

__PACKAGE__->meta->make_immutable();
