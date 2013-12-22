package App::Happyman::Delay;
use v5.18;
use warnings;

use AnyEvent;
use parent 'Exporter';

our @EXPORT = qw(delayed_randomly);

sub delayed_randomly (&) {
    my ($code) = @_;
    
    my $timer;
    $timer = AE::timer rand(2), 0, sub {
        undef $timer;
        $code->();
    };
}

1;
