+++
title = "Puppet tests using vagrant"
date = "2013-12-10"
slug = "2013/12/10/puppet-tests-using-vagrant"
Categories = []
+++

XXX Work in progress.

## Intro
Read first

* http://www.example42.com/?q=Example42%20Puppet%20Playground
* http://grahamgilbert.com/blog/2013/02/13/building-a-test-puppet-master-with-vagrant/
* http://theholyjava.wordpress.com/2013/09/03/test-puppet-config-of-an-existing-node-using-puppet-master-inside-vagrant/
* http://journal.ryanmccue.info/209/vagrant-puppet-master-pt-1/
* http://journal.ryanmccue.info/209/vagrant-puppet-master-pt-1/
* http://brokenhaze.com/blog/2013/07/25/puppet-workflow-with-vagrant/
* http://stackoverflow.com/questions/14168588/vagrant-running-a-puppet-master-with-a-puppet-agent
* http://java.dzone.com/articles/test-puppet-config-existing
* https://github.com/garethr/puppetmaster-vagrant

## Prerequisites
* [git](http://git-scm.com/)
* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](http://www.vagrantup.com/)

``` sh Yaourting VirtualBox, git and Vagrant on Archlinux
yaourt -S git
yaourt -S virtualbox virtualbox-guest-iso
yaourt -S vagrant
```

## VMs list
* One puppet master running Debian 7 64bits
* One puppet client running Debian 7 64bits
* One puppet client running Scientific Linux 5.x 64 bits
* One puppet client running Scientific Linux 6.x 64 bits
* One puppet client running CentOS 6.x 64 bits

## Planned workflow

## Boxes URLs

### Boxes repositories
* http://puppet-vagrant-boxes.puppetlabs.com/
* http://www.vagrantbox.es/

### Boxes list
* Debian 7 64 bits - http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box
* Scientific Linux 5.x 64 bits -
* Scientific Linux 6.x 64 bits -  http://lyte.id.au/vagrant/sl6-64-lyte.box
* CentOS 6.x 64 bits - http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210-nocm.box

## Box installation
Box installation will take some time as the boxes have to be downloaded locally.

```
vagrant box add debian7-64 http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box
vagrant box add sl6-64 http://lyte.id.au/vagrant/sl6-64-lyte.box
vagrant box add centos6-64 http://puppet-vagrant-boxes.puppetlabs.com/centos-64-x64-vbox4210-nocm.box
```

## Vagrant configuration

Puppet will be boostraped using a small shell script

``` sh shell/base.sh
#!/bin/sh

if [ $(id -u) -ne 0 ]; then
  echo 'This script must be run as root.' >&2
  exit 1
fi

if which puppet > /dev/null 2>&1; then
  echo 'Puppet is already installed'
  exit 0
fi

# Add puppetlabs repo definitions
echo 'deb http://apt.puppetlabs.com wheezy main' > /etc/apt/sources.list.d/puppetlabs.list
echo 'deb http://apt.puppetlabs.com wheezy dependencies' > /etc/apt/sources.list.d/puppetlabs-dependencies.list

# Add puppetlabs repo key
apt-key adv --keyserver keyserver.ubuntu.com --recv 4BD6EC30

# Update packages list
aptitude update

# Upgrade system
# Not working yet due to debconf wanting input
#aptitude -V -y upgrade
#aptitude -V -y dist-upgrade

# Install puppet
aptitude -y install puppet
echo 'Puppet successfully installed'
```

Then nitial role will be set using another shell script
``` sh shell/role.sh
#!/bin/sh

if [ $(hostname) = 'puppet' ]; then
  echo 'role=puppetmaster' >> /etc/company.conf
fi
if [ $(hostname) = 'client' ]; then
  echo 'role=puppet' >> /etc/company.conf
fi
```

And the puppetmaster is boostraped using the puppet apply provider.
The client will get its configuration from the puppetmaster using the
puppet agent provider.

Two directories from the host are made available to the guest, they
contain the puppet modules that will be used for the puppetmaster
bootstrap:
* Local puppet modules are available in the relatvie ../../dist
  directory
* A local copy of the remote puppet modules managed using the Puppetfile
  is made using r10k (using a symbolicaly linked Puppetfile)

```sh
gem install r10k
r10k -v INFO puppetfile install
```

```ruby Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "debian7-64-nocm"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "http://puppet-vagrant-boxes.puppetlabs.com/debian-70rc1-x64-vbox4210-nocm.box"

  # Setup the Puppet master
  config.vm.define :master do |master|
    # Configure memory
    master.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    # Set hostname - role will be set based onto it
    master.vm.hostname = "puppet.local"
    # Shell provisionner for bootstrapping puppet agent
    master.vm.provision "shell", path: "shell/base.sh"
    # Shell provisionner for bootstrapping gnubila conf
    master.vm.provision "shell", path: "shell/role.sh"

    # Share puppet develop branch as puppet production folder
    master.vm.synced_folder  "../../../puppet", "/puppet"
    master.vm.synced_folder  "../../hieradata", "/vagrant/hieradata"

    # Create a puppetmaster using puppet apply
    master.vm.provision :puppet do |puppet|
      # Path on host to puppet manifests
      puppet.manifests_path = "../../manifests"
      # Relative path to the default manifest
      # Path on host to puppet modules
      puppet.module_path = ["../../dist", "modules"]
      puppet.manifest_file  = "site.pp"
      # Path on host to hiera.yaml
      puppet.hiera_config_path = "puppet/hiera.yaml"
      # Working directory on the guest
      puppet.working_directory = '/vagrant'
    end
  end
  config.vm.define :client do |client|
    # Configure memory
    client.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024"]
    end
    # Set hostname - role will be set based onto it
    client.vm.hostname = "client.local"
    # Shell provisionner for bootstrapping puppet agent
    client.vm.provision "shell", path: "base.sh"
    # Shell provisionner for bootstrapping gnubila conf
    client.vm.provision "shell", path: "role.sh"
    # TODO Configure server using puppet agent against the master vm
  end
end
```

A copy of the hiera.yaml has been made with a custom datadir
configuration to allow puppet apply to find the conf exposed into the vm
by Vagrant.

## Go play!

The boxes are started using
```sh
vagrant up
```

* Connect using ssh

```
vagrant ssh master
vagrant ssh client
```

## Later
### Creating custom boxes using veewee
- https://github.com/jedi4ever/veewee
- https://github.com/puppetlabs/puppet-vagrant-boxes
