package App::Happyman::Plugin::PeekURI;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::HTTP;
use Coro;
use JSON;
use List::MoreUtils qw(natatime);
use Try::Tiny;
use URI;
use URI::Find;
use XML::LibXML;

sub _ignore_link {
}

sub _fetch_tweet_text {
  my ($self, $uri) = @_;
  $uri =~ m{/(\d+)$};
  return unless $1;

  http_get("http://api.twitter.com/1/statuses/show/$1.json", Coro::rouse_cb);
  my ($body, $headers) = Coro::rouse_wait();
  my $data = decode_json($body);
  return unless $data->{text};

  return 'Tweet by @' . $data->{user}{screen_name} . ': ' . $data->{text};
}

sub _fetch_html_title {
  my ($self, $uri) = @_;
  my $request_headers = {
    Range => 'bytes=0-20000',
  };

  http_get($uri, headers => $request_headers, Coro::rouse_cb);
  my ($data, $response_headers) = Coro::rouse_wait();

  if ($response_headers->{'Status'} !~ /^2/) {
    my ($status, $reason) = @{ $response_headers }{'Status', 'Reason'};
    return "$status $reason";
  }

  return if $response_headers->{'content-type'} !~ /html/;
  return unless $data;

  my $tree = XML::LibXML->load_html(
    string => $data,
    recover => 1,
  );

  my $node = $tree->findnodes('//title')->[0];
  my $title = $node ? $node->textContent : 'no title';
  $title =~ s/\n/ /g;
  return $title;
}

sub _find_uris {
  my ($self, $body) = @_;
  my @uris;
  my $finder = URI::Find->new(sub {
    push @uris, URI->new($_[0]);
  });
  $finder->find(\$body);
  
  return @uris;
}

sub _peek_uri {
  my ($self, $uri) = @_;
 
  my @peekers = (
   [ qr/(^|\.)ibash\.de$/ => \&_ignore_link ],
   [ qr/\.wikipedia\.org$/ => \&_ignore_link ],
   [ qr/^twitter\.com$/ => \&_fetch_tweet_text ],
   [ qr/./ => \&_fetch_html_title ],
  );
  
  for (@peekers) {
    my ($pattern, $cb) = @$_;
    if ($uri->host =~ $pattern) {
      return $cb->($self, $uri);
    }
  }  
}

sub on_message {
  my ($self, $sender, $body) = @_;
  
  for ($self->_find_uris($body)) {
    my $notice = $self->_peek_uri($_);
    $self->conn->send_notice($notice) if $notice;
  }
}

__PACKAGE__->meta->make_immutable();
