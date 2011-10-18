package App::Happyman::Plugin;
use 5.014;
use Moose::Role;

has 'conn' => (
  is => 'rw',
  isa => 'App::Happyman::Connection',
);

1;
