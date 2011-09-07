package App::Happyman::Plugin::PeekURI;
use Moose;
use feature qw(say);

with 'App::Happyman::Plugin';

use AnyEvent::HTTP;
use JSON;
use List::MoreUtils qw(natatime);
use Try::Tiny;
use URI;
use URI::Find;
use XML::LibXML;

my %peekers = (
  qr/\.ibash\.de$/ => sub {},
  qr/\.wikipedia\.org$/ => sub {},
  qr/^twitter\.com$/ => sub {
    my ($self, $channel, $uri) = @_;
    print "$uri\n";
    $uri =~ m{status/(\d+)};
    return unless $1;

    $uri = "http://api.twitter.com/1/statuses/show/$1.json";
    http_get($uri, sub {
      my ($body, $headers) = @_;
      my $data = decode_json($body);

      if ($data->{text}) {
        my $msg = 'Tweet by @' . $data->{user}{screen_name} . ': ' 
                . $data->{text};

        $self->conn->send_notice($channel, $msg);
      }
    });
  },
  qr// => sub {
    my ($self, $channel, $uri) = @_;
    my $headers = {
      Range => 'bytes=0-20000',
    };

    http_get($uri, headers => $headers, sub {
      my ($data, $headers) = @_;

      return if $headers->{'content-type'} ne 'text/html' and
                $headers->{'content-type'} ne 'application/xhtml+xml';

      try {
        my $tree = do {
          local $SIG{__WARN__} = sub { };
          XML::LibXML->load_html(
            string => $data,
            recover => 1,
          );
        };
        return unless $tree;

        my $node = $tree->findnodes('//title')->[0];
        return unless $node;

        my $title = $node ? $node->textContent : 'no title';
        return unless $title;

        $title =~ s/\n/ /g;
        $self->conn->send_notice($channel, "$title");
      }
      catch {
        warn "$_";
      };
    });
  },
);

sub on_channel_message {
  my ($self, $sender, $channel, $body) = @_;

  my @uris;
  my $finder = URI::Find->new(sub {
    push @uris, URI->new($_[0]);
  });
  $finder->find(\$body);

  foreach my $uri (@uris) {
    say $uri;
    while (my ($pattern, $cb) = each %peekers) {
      if ($uri->host =~ $pattern) {
        $cb->($self, $channel, $uri);
      }
    }
  }
}

__PACKAGE__->meta->make_immutable();
