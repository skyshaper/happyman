package App::Happyman::Plugin::Cobe;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent;
use AnyEvent::Handle;
use IPC::Open2;

has _child => (
    is      => 'rw',
    lazy    => 1,
    builder => '_spawn_child',
);

has [qw/_in _out/] => (
    is  => 'rw',
    isa => 'AnyEvent::Handle',
);

has brain => (
    is      => 'ro',
    isa     => 'Str',
    default => 'cobe.sqlite',
);

sub BUILD {
    my ($self) = @_;
    $self->_child;
}

sub _spawn_child {
    my ($self) = @_;

    my ( $in, $out );

    my $pid = open2( $out, $in,
        './python/bin/python ./python/cobe_pipe.py ' . $self->brain );
    binmode $out, ':encoding(UTF-8)';

    $self->_in( AnyEvent::Handle->new( fh => $in ) );
    $self->_out( AnyEvent::Handle->new( fh => $out ) );

    return AE::child(
        $pid,
        sub {
            my ( $pid, $status ) = @_;
            warn "$pid exited with status $status\n";
            $self->_child( $self->_spawn_child );
        },
    );
}

sub on_message {
    my ( $self, $msg ) = @_;
    $self->_log_debug( 'Learning: ' . $msg->text );
    $self->_in->push_write( 'learn ' . $msg->text . "\n" );

    if ( $msg->addressed_me ) {
        $self->_log_debug( 'Sending to Python: ' . $msg->text );
        $self->_in->push_write( 'reply ' . $msg->text . "\n" );
        $self->_out->push_read(
            line => sub {
                my ( undef, $line ) = @_;
                $self->_log(
                    'Replying to ' . $msg->sender_nick . ': ' . $line );
                $msg->reply_on_channel($line);
            }
        );
    }
}

__PACKAGE__->meta->make_immutable;
