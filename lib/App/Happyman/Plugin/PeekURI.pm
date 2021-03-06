package App::Happyman::Plugin::PeekURI;
use v5.14;
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

# Overrides _build_ua from App::Happyman::Plugin
sub _build_ua {
    my ($self) = @_;
    return Mojo::UserAgent->new()->max_redirects(3);
}


sub _ignore_link {
    my ( $self, $uri ) = @_;
    return;
}

sub _fetch_tweet_text {
    my ( $self, $uri ) = @_;
    $uri =~ m{status(es)?/(?<id>\d+)};
    return unless $+{id};

    $self->_log_debug("Fetching $uri");
    $self->_twitter->get(
        "statuses/show/$+{id}",
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
                if (not $error_response->{errors} or not @{ $error_response->{errors} } ) {
                    $self->conn->send_notice_to_channel(
                        "Twitter: unknown error");
                }
            }
        }
    );
    return;
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

            if (not $tx->res->dom->at($selector)) {
                $self->conn->send_notice_to_channel(
                    "PeekURI: Unable to find content at selector '$selector'" );
            }

            my $text = $tx->res->dom->at($selector)->all_text;
            $text =~ s{\n}{ }gx;

            $self->conn->send_notice_to_channel( $text );
        }
    );

    return;
}

sub _fetch_html_title {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, 'title' );
    return;
}

sub _fetch_html_tweet {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, 'div.js-original-tweet p.tweet-text' );
    return;
}

sub _fetch_mobile_wikipedia_title {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, '#content p' );
    return;
}

sub _fetch_wikipedia_title {
    my ( $self, $uri ) = @_;
    $self->_fetch_and_extract_from_dom( $uri, '#mw-content-text p' );
    return;
}

sub _scan_text_for_uris {
    my ( $self, $text ) = @_;
    my @peekers = (
        [ qr/(^|\.)ibash\.de$/     => \&_ignore_link ],
        [ qr/\.m\.wikipedia\.org$/ => \&_fetch_mobile_wikipedia_title ],
        [ qr/\.wikipedia\.org$/    => \&_fetch_wikipedia_title ],
        [ qr/^twitter\.com$/       => \&_fetch_html_tweet ],
        [ qr/./                    => \&_fetch_html_title ],
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
    $finder->find( \$text );
    return;

}

sub on_message {
    my ( $self, $msg ) = @_;
    $self->_scan_text_for_uris( $msg->text );
}

sub on_action {
    my ( $self, $action ) = @_;
    $self->_scan_text_for_uris( $action->text );
}

__PACKAGE__->meta->make_immutable();
