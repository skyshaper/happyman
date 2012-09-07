package App::Happyman::Plugin::SATQ;
use v5.16;
use Moose;

with 'App::Happyman::Plugin';

use Coro;
use LWP::Protocol::AnyEvent::http;
use LWP::UserAgent;

has '_buffer' => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has [qw(uri credentials_netloc credentials_realm credentials_user       
     credentials_password)] => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has '_ua' => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    builder => '_build_ua',
    lazy => 1,
);

sub _build_ua {
    my ($self) = @_;
    
    my $ua = LWP::UserAgent->new();
    say 
        $self->credentials_netloc,
        $self->credentials_realm,
        $self->credentials_user,
        $self->credentials_password;
    $ua->credentials(
        $self->credentials_netloc,
        $self->credentials_realm,
        $self->credentials_user,
        $self->credentials_password,
    );
    
    return $ua;
}

sub _append_buffer {
    my ($self, $line) = @_;

    if (@{ $self->_buffer } >= 10) {
        shift $self->_buffer; 
    }
    push $self->_buffer, $line;
}

sub _post_quote {
    my ($self) = @_;
    
    my $resp = $self->_ua->post($self->uri, {
        'quote[raw_quote]' => join("\n", @{ $self->_buffer }),
    });
    
    if ($resp->code == 302) {
        return $resp->header('Location');
    }
    else {
        return $resp->status_line;
    }
}

sub on_message {
    my ($self, $msg) = @_;
    

    if ($msg->full_text =~ /^\!quote\s*$/) {
        $msg->reply($self->_post_quote());
    }
    
    my $line = sprintf('<%s> %s', $msg->sender_nick, $msg->full_text);
    $self->_append_buffer($line);

}

__PACKAGE__->meta->make_immutable();
