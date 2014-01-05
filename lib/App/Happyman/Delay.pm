package App::Happyman::Delay;
use v5.16;
use warnings;

use AnyEvent;
use parent 'Exporter';

## no critic (ProhibitAutomaticExportation)
our @EXPORT = qw(delayed_randomly);

## no critic (ProhibitSubroutinePrototypes)
sub delayed_randomly (&) {
    my ($code) = @_;

    my $timer;
    $timer = AE::timer rand(2), 0, sub {
        undef $timer;
        $code->();
    };
    return;
}

1;
