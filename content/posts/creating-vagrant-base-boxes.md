+++
title = "creating vagrant base boxes"
date = "2014-01-17"
slug = "2014/01/17/creating-vagrant-base-boxes"
Categories = []
+++
## Create a VM inside VirtualBox

* No usb
* No audio
* One dynamic disk (10GiB)
* 512 MiB of RAM
* One vcpu
* One network card in NAT mode

## Install the base system, as minimal as possible

### Scientific Linux 5
* Retrieve ISOs CD 1 and 2

``` sh
wget http://ftp1.scientificlinux.org/linux/scientific/5x/iso/x86_64/cd/SL.510.110513.CD.x86_64.disc{1,2}.iso
```

* Boot CD
* Use basic video driver installation
* Use default configuration
  * except:
    * DHCP for ipv6
    * Deselct every packages sets
* Use vagrant as root password

### Scientific Linux 6
* Retrieve netinstall ISO CD

``` sh
wget http://ftp.scientificlinux.org/linux/scientific/6x/x86_64/iso/SL-64-x86_64-2013-03-18-boot.iso
```

* Boot CD
* Use network install URL:
* Use default configuration
* Use vagrant as root password

Debian 7: retrieve netinstall ISO CD

``` sh
wget http://cdimage.debian.org/debian-cd/7.3.0/amd64/iso-cd/debian-7.3.0-amd64-netinst.iso
```

## System configuration

### Scientific Linux 5/6
* Update system and reboot if kernel was updated

``` sh
yum clean all && yum update -y
reboot
```

* Add a vagrant user with vagrant as password

``` sh
adduser vagrant
passd vagrant
```

* Configure password-less sudo for vagrant user

``` sh
visudo
Default:vagrant !requiretty
vagrant ALL=(ALL) NOPASSWD: ALL
```

* Configure ssh server

``` sh
sed -i 's/^#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
```

* Configure ssh authorized_keys for vagrant user

``` sh
mkdir ~vagrant/.ssh
curl -o ~/vagrant/.ssh/authorized_keys \
  https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 0700 ~vagrant/.ssh
chmod 0600 ~vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant ~vagrant/.ssh
```

### Scientific Linux 6

Minimal SL6 install does not install acpid nor perl

``` sh
yum install -y acpid perl
service acpid start
```

## VirtualBox Additions installation

### Scientific Linux 5/6

* Insert Guest additions CD image using VirtualBox device menu
* Install required software for build the VirtualBox additions

``` sh
yum install -y gcc make kernel-devel
```

* Build and install VirtualBox additions

Error about OpenGL or Window System drivers are "normal".

``` sh
mount /dev/cdrom /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt
```

## Cleaning image

### Scientific Linux 5/6

``` sh
yum clean all
: > /var/log/messages
: > /var/log/secure
: > ~/.bash_history
kill -9 $$
```

ACPI shutdown VM using VirtualBox Machine menu.

## Packing the boxes

### Scientific Linux 5

``` sh
vagrant package --output sl5-64-VB436-nocm.box --base scientificlinux5
vagrant package --output sl6-64-VB436-nocm.box --base scientificlinux6
```

## Testing the boxes

``` sh
vagrant box add sl5-64-nocm sl5-64-VB436-nocm.box
vagrant box add sl6-64-nocm sl6-64-VB436-nocm.box
```

``` sh
mkdir ~/sl5-64-nocm-tests && cd $_
vagrant init sl5-64-nocm
vagrant up
vagrant ssh
ping -c 3 gnu.org
sudo -s
exit
exit
vagrant destroy -f
cd ..
rm -rf ~/sl5-64-nocm-tests
```

``` sh
mkdir ~/sl6-64-nocm-tests && cd $_
vagrant init sl6-64-nocm
vagrant up
vagrant ssh
ping -c 3 gnu.org
sudo -s
exit
exit
vagrant destroy -f
cd ..
rm -rf ~/sl6-64-nocm-tests
```
