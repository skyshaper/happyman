package App::Happyman::Action;
use v5.18;
use Moose;
use namespace::autoclean;

has [qw(text sender_nick)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub BUILDARGS {
    my ( $self, %args ) = @_;
    
    $args{text} =~ s/^\s+|\s+$//g;
    return \%args;
}

1;
