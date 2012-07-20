package App::Happyman::Plugin::OftcNickserv;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub on_registered {
    my ( $self ) = @_;
    
    $self->conn->send_private_message( 'NickServ', 
        join(' ', 'IDENTIFY', $self->password, $self->conn->nick));
}

__PACKAGE__->meta->make_immutable();
