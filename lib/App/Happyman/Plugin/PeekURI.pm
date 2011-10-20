package App::Happyman::Plugin::PeekURI;
use 5.014;
use Moose;

with 'App::Happyman::Plugin';

use AnyEvent::HTTP;
use JSON;
use List::MoreUtils qw(natatime);
use Try::Tiny;
use URI;
use URI::Find;
use XML::LibXML;

my @peekers = (
  [ qr/(^|\.)ibash\.de$/ => sub {} ],
  [ qr/\.wikipedia\.org$/ => sub {} ],
  [ qr/^twitter\.com$/ => sub {
    my ($self, $uri) = @_;
    $uri =~ m{(\d+)};
    return unless $1;

    $uri = "http://api.twitter.com/1/statuses/show/$1.json";
    http_get($uri, sub {
      my ($body, $headers) = @_;
      my $data = decode_json($body);

      if ($data->{text}) {
        my $msg = 'Tweet by @' . $data->{user}{screen_name} . ': ' 
                . $data->{text};

        $self->conn->send_notice($msg);
      }
    });
  } ],
  [ qr/./ => sub {
    my ($self, $uri) = @_;
    my $headers = {
      Range => 'bytes=0-20000',
    };

    http_get($uri, headers => $headers, sub {
      my ($data, $headers) = @_;

      if ($headers->{'Status'} !~ /^2/) {
        my ($status, $reason) = @{ $headers }{'Status', 'Reason'};
        $self->conn->send_notice("$status $reason");
        return;
      }

      return if $headers->{'content-type'} !~ /html/;
      return if not $data;

      my $tree = do {
        local $SIG{__WARN__} = sub { };
        XML::LibXML->load_html(
          string => $data,
          recover => 1,
        );
      };

      my $node = $tree->findnodes('//title')->[0];
      my $title = $node ? $node->textContent : 'no title';
      $title =~ s/\n/ /g;
      $self->conn->send_notice($title);
    });
  } ],
);

sub on_message {
  my ($self, $sender, $body) = @_;

  my @uris;
  my $finder = URI::Find->new(sub {
    push @uris, URI->new($_[0]);
  });
  $finder->find(\$body);

  foreach my $uri (@uris) {
    foreach (@peekers) {
      my ($pattern, $cb) = @$_;
      if ($uri->host =~ $pattern) {
        $cb->($self, $uri);
        return
      }
    }
  }
}

__PACKAGE__->meta->make_immutable();
