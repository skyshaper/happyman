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

on 'develop' => sub {
    requires 'AnyEvent::HTTP';
    requires 'AnyEvent::HTTPD';
    requires 'Data::Handle';
    requires 'LWP::Protocol::AnyEvent::http';
    requires 'LWP::UserAgent';
    requires 'Test::Spec';
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
};