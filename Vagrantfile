# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = '2'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = 'precise64'

  config.vm.network :forwarded_port, guest: 6666, host: 6666
  config.vm.network :forwarded_port, guest: 6667, host: 6667

  config.vm.provision 'shell', path: './script/vagrant_dependencies'
end
