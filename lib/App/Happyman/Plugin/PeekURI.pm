package App::Happyman::Plugin::PeekURI;
use v5.18;
use Moose;
use namespace::autoclean;

with 'App::Happyman::Plugin';

use AnyEvent::Twitter;
use JSON;
use List::MoreUtils qw(natatime);
use Mojo::UserAgent;
use URI::Find;
use URI::URL;

has twitter_consumer_key => (
    is      => 'ro',
    isa     => 'Str',
    default => 'B7uwUIJRlaQJ3RHYslZuNw',
);

has twitter_consumer_secret => (
    is      => 'ro',
    isa     => 'Str',
    default => 'KE3aHkVjT0HTupQICckWyOqmPbXHMC9cg4z9pZnVQk',
);

has twitter_token => (
    is      => 'ro',
    isa     => 'Str',
    default => '1423133221-8czqhTAF92WBeZzuxW8k9uH7dQlhTn2WHKv2wcP',
);

has twitter_token_secret => (
    is      => 'ro',
    isa     => 'Str',
    default => 'EyRxoN5ivGYQayPn8DXjNOdxWtDksEeDJxjYwuEBrnE',
);

has _twitter => (
    is      => 'ro',
    isa     => 'AnyEvent::Twitter',
    lazy    => 1,
    builder => '_build_twitter',
);

sub _build_twitter {
    my ($self) = @_;
    return AnyEvent::Twitter->new(
        consumer_key    => $self->twitter_consumer_key,
        consumer_secret => $self->twitter_consumer_secret,
        token           => $self->twitter_token,
        token_secret    => $self->twitter_token_secret,
    );
}

sub _ignore_link {
    my ( $self, $uri ) = @_;
}

sub _fetch_tweet_text {
    my ( $self, $uri ) = @_;
    $uri =~ m{status/(\d+)};
    return unless $1;

    $self->_log_debug("Fetching $uri");
    $self->_twitter->get(
        "statuses/show/$1",
        sub {
            my ( $header, $response, $reason, $error_response ) = @_;

            if ($response) {
                $self->conn->send_notice_to_channel( 'Tweet by @'
                        . $response->{user}{screen_name} . ': '
                        . $response->{text} );
            }
            else {
                for my $error ( @{ $error_response->{errors} } ) {
                    $self->conn->send_notice_to_channel(
                        "Twitter: $error->{code}: $error->{message}");
                }
            }
        }
    );
}

sub _fetch_and_extract_from_dom {
    my ( $self, $uri, $selector ) = @_;
    $self->_log_debug("Fetching $uri");
    $self->_ua->get(
        $uri,
        { Range => 'bytes=0-20000' },
        sub {
            my ( $ua, $tx ) = @_;
            if ( !$tx->success ) {
                $self->conn->send_notice_to_channel( $tx->error );
                return;
            }

            return if $tx->res->headers->content_type !~ /html/;

            $self->conn->send_notice_to_channel(
                $tx->res->dom->at($selector)->all_text );
        }
    );

    return;
}

sub _fetch_html_title {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, 'title' );
}

sub _fetch_wikipedia_title {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, '#mw-content-text p' );
}

sub on_message {
    my ( $self, $msg ) = @_;
    my @peekers = (
        [ qr/(^|\.)ibash\.de$/  => \&_ignore_link ],
        [ qr/\.wikipedia\.org$/ => \&_fetch_wikipedia_title ],
        [ qr/^twitter\.com$/    => \&_fetch_tweet_text ],
        [ qr/./                 => \&_fetch_html_title ],
    );

    my $finder = URI::Find->new(
        sub {
            my ( $uri_obj, $uri_str ) = @_;
            $self->_log("Found URI: $uri_str");
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
