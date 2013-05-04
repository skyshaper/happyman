package App::Happyman::Plugin::PeekURI;
use v5.16;
use Moose;
use Method::Signatures;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent::Twitter;
use JSON;
use List::MoreUtils qw(natatime);
use Mojo::UserAgent;
use URI::Find;
use URI::URL;
use XML::LibXML;

has [
    qw(twitter_consumer_key twitter_consumer_secret twitter_token twitter_token_secret)
    ] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has _twitter => (
    is      => 'ro',
    isa     => 'AnyEvent::Twitter',
    lazy    => 1,
    builder => '_build_twitter',
);



method _build_twitter {
    return AnyEvent::Twitter->new(
        consumer_key    => $self->twitter_consumer_key,
        consumer_secret => $self->twitter_consumer_secret,
        token           => $self->twitter_token,
        token_secret    => $self->twitter_token_secret,
    );
}


method _ignore_link (Str $uri) {
}

method _fetch_tweet_text (Str $uri) {
    $uri =~ m{/(\d+)$};
    return unless $1;

    $self->_twitter->get(
        "statuses/show/$1",
        func ( $header, $response, $reason ) {
            return unless $response->{text};

            $self->conn->send_notice( 'Tweet by @'
                    . $response->{user}{screen_name} . ': '
                    . $response->{text} );
        }
    );
}

method _fetch_html_title (Str $uri) {
    $self->_ua->get($uri, { Range => 'bytes=0-20000' }, func ($ua, $tx) {
        if ( !$tx->success ) {
            my ($err, $code) = $tx->error;
            return "$code err";
        }

        return if $tx->res->headers->content_type !~ /html/;

        $self->conn->send_notice($tx->res->dom->html->head->title->text);
    });

    return;
}

method on_message (App::Happyman::Message $msg) {
    my @peekers = (
        [ qr/(^|\.)ibash\.de$/  => \&_ignore_link ],
        [ qr/\.wikipedia\.org$/ => \&_ignore_link ],
        [ qr/^twitter\.com$/    => \&_fetch_tweet_text ],
        [ qr/./                 => \&_fetch_html_title ],
    );

    my $finder = URI::Find->new(
        func (URI::URL $uri_obj, Str $uri_str) {
            for (@peekers) {
                my ( $pattern, $cb ) = @$_;
                if ( $uri_obj->host =~ $pattern ) {
                    return $cb->( $self, $uri_str );
                }
            }
        }
    );
    $finder->find( \$msg->text );
}

__PACKAGE__->meta->make_immutable();
