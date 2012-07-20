package App::Happyman::Plugin;
use v5.16;
use Moose::Role;

has 'conn' => (
    is  => 'rw',
    isa => 'App::Happyman::Connection',
);

1;
