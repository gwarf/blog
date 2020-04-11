+++
title = "xenserver installation using http source"
date = "2014-04-18"
slug = "2014/04/18/xenserver-installation-using-http-source"
Categories = []
+++

Small notes on installing XenServer using a remote installation source.
See

[Citrix Official Documentation](http://support.citrix.com/proddocs/topic/xenserver/xs-wrapper.html)
for more.

## Downloading XenServer

Log into [Citrix site](https://www.citrix.com) as login is required in
order to see the Product Software entry into the Find Downloads tool.

## Extracting ISO content

``` sh
mkdir xenserver-6.0.0_iso
sudo mount -o loop XenServer-6.0.0-install-cd.iso xenserver-6.0.0_iso
sudo mkdir -p /srv/mirror/xen/xenserver/6.0.0/
sudo cp -r xenserver-6.0.0_iso/* /srv/mirror/xen/xenserver/6.0.0/
```

## Making ISO available at a reachable http/ftp server

Simple alias example for apache:

```
Alias /xen /srv/mirror/xen
<Directory /srv/mirror/xen>
   Options Indexes FollowSymLinks
   AllowOverride None
   Order deny,allow
   deny from all
   allow from all
</Directory>
```

Installation files will be available at ```http://server.domain.tld/xen/xenserver/6.0.0/```.

## Installing XenServer

* Boot installation ISO on server
* Configure network
* Configure XenServer installer to retrieve files of http/ftp source
