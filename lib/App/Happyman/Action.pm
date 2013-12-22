package App::Happyman::Action;
use v5.18;
use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;

subtype 'TrimmedStr'
    => as 'Str'
    => where { /^\S .* \S$/x };

coerce 'TrimmedStr'
    => from 'Str'
    => via { s/^\s+ | \s+$//gxr };


has 'sender_nick' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);
has 'text' => (
    is       => 'ro',
    isa      => 'TrimmedStr',
    required => 1,
    coerce   => 1,
);

1;
