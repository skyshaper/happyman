#!/usr/bin/env perl

use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'App::Happyman',
  dist_version => '0.0',
  license => 'unrestricted',
  requires => {
    perl => '5.10.',
    'AnyEvent' => 0,
    'AnyEvent::HTTP' => 0,
    'AnyEvent::Handle' => 0,
    'AnyEvent::IRC::Client' => 0,
    'AnyEvent::IRC::Util' => 0,
    'AnyEvent::Impl::Perl' => 0,
    'AnyEvent::Socket' => 0,
    'AnyEvent::Strict' => 0,
    'AnyEvent::Worker' => 0,
    'Class::Load' => 0,
    'Config::INI::Reader' => 0,
    'Encode' => 0,
    'Hailo' => 0,
    'JSON' => 0,
    'List::MoreUtils' => 0,
    'Moose' => 0,
    'Moose::Role' => 0,
    'Try::Tiny' => 0,
    'URI' => 0,
    'URI::Find' => 0,
    'XML::LibXML' => 0,
  },
)->create_build_script();
