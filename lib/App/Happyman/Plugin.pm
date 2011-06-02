package App::Happyman::Plugin;
use Moose::Role;

has 'conn' => (
  is => 'rw',
  isa => 'App::Happyman::Connection',
);

1;
