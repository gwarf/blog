+++
title = "regenerating puppet certificates"
date = "2014-04-10"
slug = "2014/04/10/regenerating-puppet-certificates"
Categories = []
+++
## Bleeding Heart...

Following the [Heartbleed](http://heartbleed.com) bug and as all Debian
stable (wheezy for the time being) are affected and as the puppetmaster
is running on debian it is a good idea
to regenerate the puppet certificates, here is a quick how-to when using
puppet with passenger on debian wheezy.

Please refer to the 
[official documentation](http://docs.puppetlabs.com/puppet/latest/reference/ssl_regenerate_certificates.html).

## On the puppet master
``` sh
service apache2 stop
cp -r /var/lib/puppet/ssl ~/puppet-ssl-backup
rm -rf /var/lib/puppet/ssl/*
# Kill the master once the CA and certs have been generated using ctrl+c
puppet master --no-daemonize --verbose
service apache2 start
```

Now a new CA has been created in /var/lib/puppet/ssl, and a cert for the
master has been generated and signed, and all the existing agent
certificates are now unknown to the CA.

``` sh
puppet cert list --all
```

The puppetdb certificates should also be updated.
``` sh
rm /etc/puppetdb/ssl/*
puppetdb ssl-setup
service puppetdb restart
```

Launch the agent on the master to check that everything is OK.
``` sh
puppet agent -tv
```

### On the puppet agents

Stop the agent if it is running and clean the SSL dir.

``` sh
service puppet stop
rm -rf /var/lib/puppet/ssl/*
```

Launch the agent to generate a cert and wait for the cert to be signed.

``` sh
puppet agent -tv --waitforcert 60
```

``` sh Sign the certificate request on the master
puppet cert list
puppet cert sign xxx.xxx.xxx
```
