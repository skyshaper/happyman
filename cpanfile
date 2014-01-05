requires 'perl', '5.16.0';

requires 'AnyEvent';
requires 'AnyEvent::IRC';
requires 'AnyEvent::Twitter';
requires 'Data::Dumper::Concise';
requires 'EV';
requires 'File::Slurp';
requires 'IO::Socket::SSL';
requires 'List::MoreUtils';
requires 'Module::Load';
requires 'Mojolicious';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Net::SSLeay';
requires 'Try::Tiny';
requires 'URI';
requires 'URI::Find';

on 'test' => sub {
    requires 'AnyEvent::HTTP';
    requires 'AnyEvent::HTTPD';
    requires 'Data::Handle';
    requires 'LWP::Protocol::AnyEvent::http';
    requires 'LWP::UserAgent';
    requires 'Test::Spec';
};

on 'develop' => sub {
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
};