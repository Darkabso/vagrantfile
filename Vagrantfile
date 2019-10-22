# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"

  config.vm.box_check_update = true

  config.vm.network :private_network, ip: "192.168.3.10"

  config.vm.hostname = "example.localdomain"

  config.vm.synced_folder "../", "/var/www/app"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
	vb.cpus = 1
  end

  config.vm.provision "file", source: "./files_sync/.", destination: "/tmp/files_sync"

  config.vm.provision "shell" do |s|
	s.path = "vagrant_boot.sh"
  end

end
