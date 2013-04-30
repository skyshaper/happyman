package App::Happyman::Plugin::PeekURI;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::HTTP;
use AnyEvent::Twitter;
use Coro;
use JSON;
use List::MoreUtils qw(natatime);
use URI;
use URI::Find;
use XML::LibXML;

has [qw(twitter_consumer_key twitter_consumer_secret twitter_token twitter_token_secret)]=> (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has _twitter => (
    is => 'ro',
    isa => 'AnyEvent::Twitter',
    lazy => 1,
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
}

sub _fetch_tweet_text {
    my ($self, $uri) = @_;
    $uri =~ m{/(\d+)$};
    return unless $1;

    $self->_twitter->get("statuses/show/$1", Coro::rouse_cb);
    my ($header, $response, $reason) = Coro::rouse_wait();
    return unless $response->{text};

    return 'Tweet by @' . $response->{user}{screen_name} . ': ' . $response->{text};
}

sub _fetch_html_title {
    my ($self, $uri) = @_;
    my $request_headers = { Range => 'bytes=0-20000', };

    http_get($uri, headers => $request_headers, Coro::rouse_cb);
    my ($data, $response_headers) = Coro::rouse_wait();

    if ($response_headers->{'Status'} !~ /^2/) {
        my ($status, $reason) = @{$response_headers}{ 'Status', 'Reason' };
        return "$status $reason";
    }

    return if $response_headers->{'content-type'} !~ /html/;
    return unless $data;

    my $encoding;
    if ($response_headers->{'content-type'} =~ /charset=(.+)/) {
        $encoding = $1;
    }

    my $tree = XML::LibXML->load_html(
        string  => $data,
        recover => 1,
        encoding => $encoding,
    );

    my $node = $tree->findnodes('//title')->[0];
    my $title = $node ? $node->textContent : 'no title';
    $title =~ s/\n/ /g;
    return $title;
}

sub _find_uris {
    my ($self, $body) = @_;
    my @uris;
    my $finder = URI::Find->new(
        sub {
            push @uris, URI->new($_[0]);
        }
    );
    $finder->find(\$body);

    return @uris;
}

sub _peek_uri {
    my ($self, $uri) = @_;

    my @peekers = (
        [ qr/(^|\.)ibash\.de$/  => \&_ignore_link ],
        [ qr/\.wikipedia\.org$/ => \&_ignore_link ],
        [ qr/^twitter\.com$/    => \&_fetch_tweet_text ],
        [ qr/./                 => \&_fetch_html_title ],
    );

    for (@peekers) {
        my ($pattern, $cb) = @$_;
        if ($uri->host =~ $pattern) {
            return $cb->($self, $uri);
        }
    }
}

sub on_message {
    my ($self, $msg) = @_;

    for ($self->_find_uris($msg->text)) {
        my $notice = $self->_peek_uri($_);
        $self->conn->send_notice($notice) if $notice;
    }
}

__PACKAGE__->meta->make_immutable();
