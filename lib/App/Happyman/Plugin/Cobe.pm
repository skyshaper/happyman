package App::Happyman::Plugin::Cobe;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent;
use IPC::Open2;
use Encode;
use open ':encoding(utf8)';

has _child => (
	is => 'rw',
	lazy => 1,
	builder => '_spawn_child',
);

has [qw/_in _out/] => (
	is => 'rw',
);

has command => (
	is => 'ro',
	isa => 'Str',
	default => './python/bin/python ./cobe_pipe.py ./cobe.sqlite',
);

sub BUILD { shift->_child }

sub _spawn_child {
	my ($self) = @_;

	my ($in, $out);

	my $pid = open2($out, $in, $self->command);

	my $child = AnyEvent->child(
		pid => $pid,
		cb => sub {
			my ($pid, $status) = @_;
			warn "$pid exited with status $status\n";
			$self->_child($self->_spawn_child);
		},
	);

	$self->_out(AnyEvent->io(
		fh => $out,
		poll => 'r',
		cb => sub {
			my $input = <$out>;
			return unless defined $input;
			chomp $input;
			$self->conn->send_message(decode('utf-8', $input));
		},
	));

	$self->_in($in);

	return $child;
}

sub on_message {
	my ($self, $sender, $body) = @_;

	$self->_in->print("learn $body\n");
}

sub on_message_me {
	my ($self, $sender, $body) = @_;

	$self->_in->print("reply $sender $body\n");
}

__PACKAGE__->meta->make_immutable;