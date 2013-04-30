package App::Happyman::Plugin::SATQ;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use Coro;
use Mojo::UserAgent;
use MIME::Base64;

has '_buffer' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has [qw(uri user password)] => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has '_ua' => (
    is => 'ro',
    isa => 'Mojo::UserAgent',
    builder => '_build_ua',
    lazy => 1,
);

sub _build_ua {
    return Mojo::UserAgent->new();
}

sub on_message {
    my ($self, $msg) = @_;

    if ($msg->full_text =~ /^\!quote\s*$/) {
        my $authorization =  'Basic ' . encode_base64(
            $self->user . ':' . $self->password, '');
        my $headers = {Authorization => $authorization};
        my $form = {
            'quote[raw_quote]' => join("\n", @{ $self->_buffer })
        };
        
        $self->_ua->post($self->uri, $headers, form => $form, sub {
            my (undef, $tx) = @_;
            $msg->reply($tx->res->headers->location || $tx->res->code);
        });
    }

    my $line = sprintf('<%s> %s', $msg->sender_nick, $msg->full_text);
    if (@{ $self->_buffer } >= 10) {
        shift $self->_buffer;
    }
    push $self->_buffer, $line;
}

__PACKAGE__->meta->make_immutable();
