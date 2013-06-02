use v5.16;
use warnings;

use App::Happyman::Test;
use Test::Spec;

use_ok('App::Happyman::Connection');
use_ok('App::Happyman::Plugin::OftcNickserv');

describe 'OftcNickserv' => sub {
    my ( $irc, $happyman );

    before sub {
        $irc = make_test_client('NickServ');
        async_sleep(5);
        $happyman = make_happyman_with_plugin(
            'OftcNickserv',
            { password => 'happypassword', }
        );
    };

    after sub {
        $happyman->disconnect_and_wait();
        disconnect_and_wait($irc);
    };

    it 'sends its password to NickServ' => sub {
        my ( undef, undef, $ircmsg )
            = wait_on_event_or_timeout( $irc, 'privatemsg', 5 );
        my $full_text = $ircmsg->{params}->[1];
        is( $full_text, 'IDENTIFY happypassword happyman' );
    };
};

runtests unless caller;
