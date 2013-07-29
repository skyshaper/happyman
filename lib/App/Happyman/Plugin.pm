package App::Happyman::Plugin;
use v5.18;
use Moose::Role;
use namespace::autoclean;

has 'conn' => (
    is  => 'ro',
    isa => 'App::Happyman::Connection',
);

has '_ua' => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    builder => '_build_ua',
    lazy    => 1,
);

sub _build_ua {
    my ($self) = @_;
    return Mojo::UserAgent->new();
}

sub _plugin_name {
    my ($self) = @_;
    my $class_name = blessed($self);
    $class_name =~ /::(\w+)$/;
    return $1;
}

sub _log {
    my ( $self, $message ) = @_;
    $self->conn->log( '[' . $self->_plugin_name . "] $message" );
}

sub _log_debug {
    my ( $self, $message ) = @_;
    $self->conn->log_debug( '[' . $self->_plugin_name . "] $message" );
}

1;
