package App::Happyman::Plugin::PeekURI;
use v5.16;
use Moose;
use Method::Signatures;

with 'App::Happyman::Plugin';

use AnyEvent::HTTP;
use AnyEvent::Twitter;
use JSON;
use List::MoreUtils qw(natatime);
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
        sub {
            my ( $header, $response, $reason ) = @_;
            return unless $response->{text};

            $self->conn->send_notice( 'Tweet by @'
                    . $response->{user}{screen_name} . ': '
                    . $response->{text} );
        }
    );
}

method _fetch_html_title (Str $uri) {
    my $request_headers = { Range => 'bytes=0-20000', };

    http_get(
        $uri,
        headers => $request_headers,
        sub {
            my ( $data, $response_headers ) = @_;

            if ( $response_headers->{'Status'} !~ /^2/ ) {
                my ( $status, $reason )
                    = @{$response_headers}{ 'Status', 'Reason' };
                return "$status $reason";
            }

            return if $response_headers->{'content-type'} !~ /html/;
            return unless $data;

            my $encoding;
            if ( $response_headers->{'content-type'} =~ /charset=(.+)/ ) {
                $encoding = $1;
            }

            my $tree = XML::LibXML->load_html(
                string   => $data,
                recover  => 1,
                encoding => $encoding,
            );

            my $node = $tree->findnodes('//title')->[0];
            my $title = $node ? $node->textContent : 'no title';
            $title =~ s/\n/ /g;

            $self->conn->send_notice($title);
        }
    );

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
