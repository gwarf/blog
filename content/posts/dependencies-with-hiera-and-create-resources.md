+++
title = "dependencies with hiera and create resources"
date = "2014-04-07"
slug = "2014/04/07/dependencies-with-hiera-and-create-resources"
Categories = []
+++
In a [nodeless setup](/blog/2013/12/11/node-less-puppet-setup-using-hiera) it
is possible to manage dependencies between resources created by
create_resources, but the syntax is quite strict and caused me some
troubles.
If the syntax is not correct the traditionnal ```Could not find
dependency``` error message will be displayed.


``` ruby site.pp
node default {
  hiera_include ('classes', [])

  $packages = hiera_hash('packages', {})
  create_resources('package', $packages)

  $services = hiera_hash('services', {})
  create_resources('service', $services)
}
```

The following won't work:

``` yaml common.yaml
services:
  mysql:
    ensure: 'running'
    require: Package['mysql-server']
```

Nor the following:

``` yaml common.yaml
services:
  mysql:
    ensure: 'running'
    require: "Package['mysql-server']"
```

But the following two syntaxes will work:

``` yaml common.yaml
+++
classes:
  - 'puppet::agent'
packages:
  mysql-server:
    ensure: 'installed'
services:
  mysql:
    ensure: 'running'
    require: Package[mysql-server]
```

``` yaml common.yaml
+++
classes:
  - 'puppet::agent'
packages:
  mysql-server:
    ensure: 'installed'
services:
  mysql:
    ensure: 'running'
    require: 'Package[mysql-server]'
```

See a full example running in Vagrant at https://github.com/gwarf/puppet-vagrant-playground
