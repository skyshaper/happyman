use v5.16;
use warnings;

use parent 'Exporter';
our @EXPORT = qw(make_connection_with_plugin);

use AnyEvent;

sub make_happyman_with_plugin {
    my ($plugin_name, $plugin_params) = @_;
    my $happyman = App::Happyman::Connection->new(
        nick    => 'happyman',
        host    => 'localhost',
        port    => 6667,
        channel => '#happyman',
    );
    my $plugin = $plugin_name->new($plugin_params);
    $happyman->add_plugin($plugin);
    return $happyman;
}

sub make_test_client {
    my $irc = AnyEvent::IRC::Client->new();
    my $cv  = AE::cv;
    $irc->reg_cb(connect => $cv);
    $irc->connect('localhost', 6667, { nick => 'HMTest' });
    my (undef, $error) = $cv->recv();
    if ($error) {
        BAIL_OUT("Failed to connect to test IRC server!: $error");
    }
    $irc->send_srv('JOIN', '#happyman');
    return $irc;
}

1;