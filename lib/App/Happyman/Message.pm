package App::Happyman::Message;
use v5.16;
use Moose;
use Method::Signatures;

has [qw(full_text text sender_nick)] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'addressed_nick' => (
    is  => 'ro',
    isa => 'Str',
);

has 'conn' => (
    is       => 'ro',
    isa      => 'App::Happyman::Connection',
    required => 1,
);

method BUILDARGS (App::Happyman::Connection $conn, Str $sender_nick, Str $full_text) {
    if ( $full_text =~ /^(\w+)[:,]\s+(.+)$/ ) {
        return {
            conn           => $conn,
            sender_nick    => $sender_nick,
            full_text      => $full_text,
            addressed_nick => $1,
            text           => $2,
        };
    }
    else {
        return {
            conn        => $conn,
            sender_nick => $sender_nick,
            full_text   => $full_text,
            text        => $full_text,
        };
    }
}

method addressed_me {
    return ( defined $self->addressed_nick
            and $self->addressed_nick eq $self->conn->nick );
}

method reply (Str $text) {
    $self->conn->send_message( $self->sender_nick . ': ' . $text );
}

1;
