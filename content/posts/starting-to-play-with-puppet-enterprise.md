---
title = "Starting to play with Puppet Enterprise"
date = "2014-02-14"
slug = "2014/02/14/starting-to-play-with-puppet-enterprise"
tags =
  - puppet
---

## Why Puppet Enterprise?

*[@work](https://gnubila.fr)* we are using puppet to manage our servers,
currently we are using Puppet Open Source edition with great satisfaction.

Being curious I always wanted to try the Puppet Enterprise edition, which is no
more free, following my server migration (moving from a FreeBSD-based OVH
dedicated server to a less expensive Kimsufi) I have to setup a new way of
managing my VMs, after some quick and opinionated reading, I dropped the idea to
use Chief and after a bit of additional readings I skipped Ansible too as I
like some puppet concepts like exported/collected resources allowing to setup a
dynamic environment.

As Puppet Enterprise is free for managing up to 10 nodes (I don't plan to have
more than 10 nodes for my personal use ;) ) it turns out it is the perfect
occasion to git it a try, so let's jump in!

## Installing Puppet Enterprise

Downloading [Puppet Enterprise](http://info.puppetlabs.com/download-pe.html)
only requires to register with an email, a mail with the download information
for the different OS will be sent.

```sh
wget https://s3.amazonaws.com/pe-builds/released/3.1.3/puppet-enterprise-3.1.3-debian-7-amd64.tar.gz
tar xf puppet-enterprise-3.1.3-debian-7-amd64.tar.gz
cd puppet-enterprise-3.1.3-debian-7-amd64/
```

```sh Archive content
% tree
.
├── answers
│   ├── agent_no_cloud.answer.sample
│   ├── agent_with_cloud.answer.sample
│   ├── console_only.answer.sample
│   ├── full_suite.answer.sample
│   ├── full_suite_existing_postgres.sample
│   ├── full_suite_existing_remote_postgres.sample
│   └── master_only.answer.sample
├── db_import_export.rake
├── erb
│   ├── auth.conf.erb
│   ├── autosign.conf.erb
│   ├── cas_client_config.yml.erb
│   ├── config.ru.erb
│   ├── console_auth_config.yml.erb
│   ├── console_auth_db_config.yml.erb
│   ├── console_auth_log_config.yml
│   ├── databases.erb
│   ├── database.yml.erb
│   ├── event_inspector_config.yml.erb
│   ├── external_node.erb
│   ├── license_status_config.yml.erb
│   ├── puppet.conf.erb
│   ├── puppetdashboard.conf.erb
│   ├── puppetdb_master.pp.erb
│   ├── puppetdb.pp.erb
│   ├── puppetmaster.conf.erb
│   ├── read_console_auth_db_config.erb
│   ├── rewrite_rubycas_config.yml.erb
│   ├── rubycas_config_upgrade_comments.txt
│   ├── rubycas_config.yml.erb
│   ├── settings.yml.erb
│   └── site.pp.erb
├── gpg
│   └── GPG-KEY-puppetlabs
├── LICENSE.txt
├── modules
│   ├── cprice404-inifile-0.10.3.tar.gz
│   ├── install_modules.txt
│   ├── puppetlabs-apt-1.1.0.tar.gz
│   ├── puppetlabs-auth_conf-0.1.7.tar.gz
│   ├── puppetlabs-firewall-0.3.0.tar.gz
│   ├── puppetlabs-java_ks-1.1.0.tar.gz
│   ├── puppetlabs-pe_accounts-2.0.1.tar.gz
│   ├── puppetlabs-pe_common-0.1.0.tar.gz
│   ├── puppetlabs-pe_mcollective-0.1.14.tar.gz
│   ├── puppetlabs-pe_postgresql-0.0.5.tar.gz
│   ├── puppetlabs-pe_puppetdb-0.0.11.tar.gz
│   ├── puppetlabs-postgresql-2.5.0.tar.gz
│   ├── puppetlabs-puppetdb-1.5.1.tar.gz
│   ├── puppetlabs-puppet_enterprise-3.1.0.tar.gz
│   ├── puppetlabs-reboot-0.1.2.tar.gz
│   ├── puppetlabs-request_manager-0.0.10.tar.gz
│   ├── puppetlabs-stdlib-3.2.0.tar.gz
│   └── ripienaar-concat-0.2.0.tar.gz
├── noask
│   └── solaris-noask
├── packages
│   ├── debian-7-amd64
│   │   ├── Packages
│   │   ├── Packages.gz
│   │   ├── pe-activemq_5.8.0-1puppet5_all.deb
│   │   ├── pe-activerecord_2.3.17-1puppet2_all.deb
│   │   ├── pe-activesupport_2.3.17-1puppet2_all.deb
│   │   ├── pe-augeas_1.1.0-1puppet1_amd64.deb
│   │   ├── pe-bundler_1.3.5-1puppet2_all.deb
│   │   ├── pe-certificate-manager_0.4.7-1puppet1_all.deb
│   │   ├── pe-certificate-manager-test_0.4.7-1puppet1_all.deb
│   │   ├── pe-cloud-provisioner_1.1.4-puppet1_all.deb
│   │   ├── pe-cloud-provisioner-libs_0.3.2-1puppet1_amd64.deb
│   │   ├── pe-console_0.3.10-1puppet1_all.deb
│   │   ├── pe-console-auth_1.2.21-1puppet1_all.deb
│   │   ├── pe-console-test_0.3.10-1puppet1_all.deb
│   │   ├── pe-event-inspector_0.1.0-1puppet1_all.deb
│   │   ├── pe-facter_1.7.3.1-1puppet1_amd64.deb
│   │   ├── pe-hiera_1.2.2.1-1puppet1_all.deb
│   │   ├── pe-httpd_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-httpd-bin_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-httpd-common_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-httpd-doc_2.2.25-1puppet4_all.deb
│   │   ├── pe-httpd-mpm-worker_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-httpd-prefork-dev_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-httpd-utils_2.2.25-1puppet4_amd64.deb
│   │   ├── pe-java_1.7.0.19-1puppet1_amd64.deb
│   │   ├── pe-libevent_2.0.13-1puppet3_amd64.deb
│   │   ├── pe-libevent-devel_2.0.13-1puppet3_amd64.deb
│   │   ├── pe-libyaml_0.1.4-1puppet3_amd64.deb
│   │   ├── pe-license_0.1.1-1puppet1_all.deb
│   │   ├── pe-license-status_0.1.5-1puppet1_all.deb
│   │   ├── pe-license-status-test_0.1.5.1-1puppet1_all.deb
│   │   ├── pe-live-management_1.2.16-1puppet1_all.deb
│   │   ├── pe-mcollective_2.2.4-1puppet2_all.deb
│   │   ├── pe-mcollective-client_2.2.4-1puppet2_all.deb
│   │   ├── pe-mcollective-common_2.2.4-1puppet2_all.deb
│   │   ├── pe-memcached_1.4.7-1puppet4_amd64.deb
│   │   ├── pe-memcached-devel_1.4.7-1puppet4_amd64.deb
│   │   ├── pe-passenger_4.0.18-1puppet3_amd64.deb
│   │   ├── pe-postgresql_9.2.4-2puppet5_amd64.deb
│   │   ├── pe-postgresql-contrib_9.2.4-2puppet5_amd64.deb
│   │   ├── pe-postgresql-devel_9.2.4-2puppet5_amd64.deb
│   │   ├── pe-postgresql-server_9.2.4-2puppet5_amd64.deb
│   │   ├── pe-puppet_3.3.3.2-1puppet1_all.deb
│   │   ├── pe-puppet-dashboard_2.0.14-1puppet1_amd64.deb
│   │   ├── pe-puppetdb_1.5.1.pe-1puppetlabs1_all.deb
│   │   ├── pe-puppetdb-terminus_1.5.1.pe-1puppetlabs1_all.deb
│   │   ├── pe-puppet-enterprise-release_3.1.3-1puppet1_all.deb
│   │   ├── pe-puppet-license-cli_0.1.6-1puppet1_all.deb
│   │   ├── pe-puppet-server_3.3.3.2-1puppet1_all.deb
│   │   ├── pe-ruby_1.9.3.448-1puppet5_amd64.deb
│   │   ├── pe-ruby-augeas_0.5.0-1puppet2_amd64.deb
│   │   ├── pe-rubycas-server_1.1.15-1puppet1_all.deb
│   │   ├── pe-rubygem-deep-merge_1.0.0-1puppet1_all.deb
│   │   ├── pe-rubygem-net-ssh_2.1.4-1puppet2_all.deb
│   │   ├── pe-rubygem-rack_1.4.5-1puppet2_all.deb
│   │   ├── pe-rubygem-sequel_3.47.0-1puppet1_all.deb
│   │   ├── pe-rubygem-stomp_1.2.9-1puppet1_all.deb
│   │   ├── pe-ruby-ldap_0.9.12-1puppet2_amd64.deb
│   │   ├── pe-ruby-mysql_2.8.2-1puppet2_amd64.deb
│   │   ├── pe-ruby-rgen_0.6.5-1puppet1_all.deb
│   │   ├── pe-ruby-shadow_2.2.0-1puppet3_amd64.deb
│   │   ├── pe-ruby-stomp_1.2.9-1puppet2_all.deb
│   │   ├── pe-tanukiwrapper_3.5.9-1puppet5_amd64.deb
│   │   ├── Release
│   │   └── Release.gpg
│   └── debian-7-amd64-package-versions.json
├── puppet-enterprise-installer
├── puppet-enterprise-uninstaller
├── README.markdown
├── support
├── supported_platforms
├── util
│   └── pe-man
├── utilities
└── VERSION

8 directories, 126 files

$ du -schx ../puppet-enterprise-3.1.3-debian-7-amd64 
254M    ../puppet-enterprise-3.1.3-debian-7-amd64
```

Yep, that's huge!

In order to install the agent on my workstation (running
[Archlinux](https://archlinux.org)) I downloaded the non packaged *nix flavour,
which is 3.6GB fat!

I will see later if thre is an alternate way.

## Installation steps

According to 
[Puppet Enterprise documentation](http://docs.puppetlabs.com/pe/latest/install_system_requirements.html)
it is required to follow the following deployment order:

- Puppet Master
- Database Support/PuppetDB
- Console
- Agents

The puppet master will be installed on the same node as the puppetdb and web
console.

Other nodes will only be agents.

### Creating the PostgreSQL databases

The node already runs a PostgreSQL database, so I won't use puppet's embedded one.

```sh PostregreSQL database creation
sudo su - postgres
postgres@misc:~$ createuser -P -D -R -S pe-puppetdb
Enter password for new role:
Enter it again: 
postgres@misc:~$ createdb -O pe-puppetdb -E UTF8 pe-puppetdb
postgres@misc:~$ createuser -P -D -R -S console
Enter password for new role: 
Enter it again: 
postgres@misc:~$ createdb -O console -E UTF8 console
postgres@misc:~$ createuser -P -D -R -S console_auth
Enter password for new role:
Enter it again: 
postgres@misc:~$ createdb -O console_auth -E UTF8 console_auth
postgres@misc:~$
```

### Launching the installation of the puppet master

The installation script asks for configurations settings and is really
straight-forward, just be sure to set y to ask for master and puppetdb
installation.

The script can also be called using a response file (see --help output).
A response file will be generated using the interactive choices.

``` sh
./puppet-enterprise-installer
```

Once the installation is over remember to open the following *3000, 8140, 61613* TCP ports.

The web Console is now reachable at: [https://host.tld.domain:3000](https://host.tld.domain:3000).

Following is the answer file generated by the installer, it can be provided to
the installer like this:

```sh using an answer file
./puppet-enterprise-installer -a answerfile
```

```sh answer file for the puppetmaster
q_all_in_one_install=y
q_backup_and_purge_old_configuration=n
q_database_host=localhost
q_database_install=n
q_database_port=5432
q_install=y
q_pe_database=n
q_puppet_cloud_install=n
q_puppet_enterpriseconsole_auth_database_name=console_auth
q_puppet_enterpriseconsole_auth_database_password=XXXXXXXXXX
q_puppet_enterpriseconsole_auth_database_user=console_auth
q_puppet_enterpriseconsole_auth_password='XXXXXXXXXXXXXXXXX'
q_puppet_enterpriseconsole_auth_user_email=baptiste@bapt.name
q_puppet_enterpriseconsole_database_name=console
q_puppet_enterpriseconsole_database_password=XXXXXXXXXX
q_puppet_enterpriseconsole_database_user=console
q_puppet_enterpriseconsole_httpd_port=3000
q_puppet_enterpriseconsole_install=y
q_puppet_enterpriseconsole_master_hostname=puppet.tld.domain
q_puppet_enterpriseconsole_smtp_host=localhost
q_puppet_enterpriseconsole_smtp_password=
q_puppet_enterpriseconsole_smtp_port=25
q_puppet_enterpriseconsole_smtp_use_tls=n
q_puppet_enterpriseconsole_smtp_user_auth=n
q_puppet_enterpriseconsole_smtp_username=
q_puppet_symlinks_install=y
q_puppetagent_certname=puppet.bapt.name
q_puppetagent_install=y
q_puppetagent_server=puppet.bapt.name
q_puppetdb_database_name=pe-puppetdb
q_puppetdb_database_password=XXXXXXXXXX
q_puppetdb_database_user=pe-puppetdb
q_puppetdb_hostname=puppet.bapt.name
q_puppetdb_install=y
q_puppetdb_port=8081
q_puppetmaster_certname=puppet.tld.domain
q_puppetmaster_dnsaltnames=puppet,puppet.tld.domain
q_puppetmaster_enterpriseconsole_hostname=localhost
q_puppetmaster_enterpriseconsole_port=3000
q_puppetmaster_install=y
q_run_updtvpkg=n
q_vendor_packages_install=y
```

### Launching the installation of a node

On agent nodes you too have to download and extract the archive.

```sh
wget https://s3.amazonaws.com/pe-builds/released/3.1.3/puppet-enterprise-3.1.3-debian-7-amd64.tar.gz
tar xf puppet-enterprise-3.1.3-debian-7-amd64.tar.gz
cd puppet-enterprise-3.1.3-debian-7-amd64/
./puppet-enterprise-installer
```

Then the installation can be launched in the same way as for the master, but
this time all the defaults should be OK, I just put the complete FQDN for the
puppet server.

```sh
./puppet-enterprise-installer
```

Following is the answer file generated by the installer.

```sh answer file
q_all_in_one_install=n
q_database_install=n
q_fail_on_unsuccessful_master_lookup=y
q_install=y
q_puppet_cloud_install=n
q_puppet_enterpriseconsole_install=n
q_puppet_symlinks_install=y
q_puppetagent_certname=host.domain.tld
q_puppetagent_install=y
q_puppetagent_server=puppet.domain.tld
q_puppetca_install=n
q_puppetdb_install=n
q_puppetmaster_install=n
q_run_updtvpkg=n
q_vendor_packages_install=y
```

## Cleaning Puppet Enterprise installation

```sh uninstalling
./puppet-enterprise-uninstaller -d -p -y
```

## First steps

Puppetlabs provides an [helpful quick start guide](http://docs.puppetlabs.com/pe/latest/quick_start.html).
