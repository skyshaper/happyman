package App::Happyman::Plugin::OftcNickserv;
use v5.14;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

has password => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has _nick_check_timer => (
    is      => 'ro',
    builder => '_build_nick_check_timer',
    lazy    => 1,
);

sub BUILD {
    my ($self) = @_;
    $self->_nick_check_timer;    # force construction
    return;
}

sub on_registered {
    my ( $self, $payload ) = @_;
    $self->_identify();
    return;
}

sub _identify {
    my ( $self ) = @_;
    $self->_log('Claiming my nick from NickServ');
    $self->conn->send_private_message( 'NickServ',
        join( ' ', 'IDENTIFY', $self->password, $self->conn->nick ) );
}

sub _check_nick {
    my ( $self ) = @_;
    $self->_log_debug('Checking nick');
    if ($self->conn->actual_nick ne $self->conn->nick) {
        $self->_identify();
    }
}

sub _build_nick_check_timer {
    my ( $self ) = @_;
    return AE::timer 60, 60, sub {
        $self->_check_nick();
    };
}

__PACKAGE__->meta->make_immutable();
