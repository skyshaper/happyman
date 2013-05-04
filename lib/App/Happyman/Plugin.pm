package App::Happyman::Plugin;
use v5.16;
use Moose::Role;
use Method::Signatures;
use namespace::autoclean;

has 'conn' => (
    is  => 'rw',
    isa => 'App::Happyman::Connection',
);

has '_ua' => (
    is      => 'ro',
    isa     => 'Mojo::UserAgent',
    builder => '_build_ua',
    lazy    => 1,
);

method _build_ua {
    return Mojo::UserAgent->new();
}

1;
