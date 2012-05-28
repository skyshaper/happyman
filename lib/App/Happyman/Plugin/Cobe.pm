package App::Happyman::Plugin::Cobe;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent;
use Coro::Handle;
use IPC::Open2;

has _child => (
    is      => 'rw',
    lazy    => 1,
    builder => '_spawn_child',
);

has [qw/_in _out/] => ( 
  is => 'rw',
  isa => 'Coro::Handle',
);

has command => (
    is      => 'ro',
    isa     => 'Str',
    default => './python/bin/python ./python/cobe_pipe.py ./cobe.sqlite',
);

sub BUILD { shift->_child }

sub _spawn_child {
    my ($self) = @_;

    my ( $in, $out );

    my $pid = open2( $out, $in, $self->command );
    binmode $out, ':encoding(UTF-8)';

    $self->_in(Coro::Handle->new_from_fh($in));
    $self->_out(Coro::Handle->new_from_fh($out));

    return AE::child($pid, sub {
            my ( $pid, $status ) = @_;
            warn "$pid exited with status $status\n";
            $self->_child( $self->_spawn_child );
        },
    );
}

sub on_message {
    my ( $self, $msg ) = @_;

    $self->_in->print('learn ' . $msg->text . "\n");
    
    if ($msg->addressed_me) {
        $self->_in->print('reply ' . $msg->text . "\n");
        $msg->reply($self->_out->readline()); 
    }
}

__PACKAGE__->meta->make_immutable;
