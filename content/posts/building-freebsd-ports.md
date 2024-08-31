---
title: "Building Freebsd Ports"
date: 2024-08-31T15:03:41+02:00
toc: true
tags:
  - freebsd
  - tutorial
  - ports
  - maintainer
---

> Post covering how to build FreeBSD ports using poudriere and portshaker.

## Back to an old platonic love

Lately, I had to came back to [FreeBSD](https://www.freebsd.org/), and take
over maintenance of some services deployed in FreeBSD.

I've been an happy FreeBSD years ago, I enjoyed this a lot, the
[handbook](https://docs.freebsd.org/en/books/handbook/) and other
documentation are marvelous, many things "just works", and I have a beard.

Long time ago I was also enjoying a very cool FreeBSD setup guide, from
[iMil](https://imil.net/blog/). And together with GCU Squad they were
spreading fun and love around the (BSD) world...

In fact I moved a bit away mainly due to lack of available time. You know,
$WORK, $kids, $LIFE, ... ^^

So thanks to $WORK, I know have the opportunity to dive again in the FreeBSD
world.

I've got a few ports to maintain (including an old port of pydf I became the
maintainer of, and that I was a bit ashamed to let rot due to lack of
time...), and I've been recently looking at options for building the ports.

This page documents the steps I followed to set my building environment up.

## My requirements - wishes

- I need a setup allowing to build ports that are managed in an
  overlay/separate port tree, typically managed in a Git repository.
- I want to build ports using
  [FreeBSD Jails](https://docs.freebsd.org/en/books/handbook/jails/)
  isolationg from the host OS and keeping it clear as much as possible.
- I want to reuse existing packages as much as possible, and especially avoid
  building big resouces hungry software like the compilers and buildrs like
  gcc, rust, and cmake. Especially as I currently don't need any customisation
  there.
- Leveraging ZFS, especially as I need to become more acustonished to it.

## Tooling

I ended up using a few tools:

- [poudriere](https://man.freebsd.org/cgi/man.cgi?poudriere): to build ports in FreeBSD Jails
- [portshaker](https://man.freebsd.org/cgi/man.cgi?portshaker): to keep ports tree udpated and merged. And also because it's a

tool that I just discovered and that was in fact created by an old colleague,
another memory from the past :)

## Setting the tools up

I will make use of [doas](https://man.freebsd.org/cgi/man.cgi?query=doas)
to run the commands as root.

### Preparing for building in Jails with Poudriere

#### Installing poudriere, portshaker and friends

```shell
doas pkg update
doas pkg install poudriere git portshaker
```

#### Setting up poudriere

The first step is to create the ZFS dataset that will be used by poudriere.

```shell
# Find a suitable ZFS pool, for me it will be zroot
zpool list

# Create a ZFS dataset for poudriere
doas zfs create zroot/poudriere

# Set the moundpoint of the ZFS dataset for poudriere
doas zfs set mountpoint=/poudriere zroot/poudriere
```

Now we have a nice ZFS dataset `zroot/poudriere` mounted on `/poudriere` and ready
to be used to host all poudriere-related things.

#### Configuring poudriere

The poudriere configuration is quite straigthforward, and I mainly add an
issue with a single point:

- From the official doc and other posts I saw, it wasn't clear to me how to
  setup BASEFS properly, sawing many examples specifying a `ZROOTFS`, but
  keeping `BASEFS` at another path.

Configuring `/usr/local/etc/poudriere.conf`:

```shell
ZPOOL=zroot
ZROOTFS=/poudriere
FREEBSD_HOST=https://download.FreeBSD.org
RESOLV_CONF=/etc/resolv.conf
BASEFS=/poudriere
DISTFILES_CACHE=/usr/ports/distfiles
USE_PORTLINT=yes
USE_TMPFS=yes
NOLINUX=yes
ALLOW_MAKE_JOBS=yes
# Retrieve latest existing packages for all components
PACKAGE_FETCH_BRANCH=latest
# Except for the ones I manage
PACKAGE_FETCH_BLACKLIST="lua-resty-openidc lua-resty-session3 rbw"
```

#### Creating the build jail

I'm currently only interested in using the latest stable release, thus
currently `14.1-RELEASE`.

See [poudriere-jail (8)](https://man.freebsd.org/cgi/man.cgi?poudriere-jail).;

```shell
# Create the build jail
doas poudriere jail -c -j 14-1-amd64 -v 14.1-RELEASE
```

#### Creating the ports tree

Poudriere will use a ports tree made of two souces:

- the upstream port tree, using it's latest version
- a repository of custom ports

In order to do this, I will make use of `portshaker`, and will just create an
empty poudriere ports tree that will later be filled using `portshaker`.

See [poudiere-ports (8)](https://man.freebsd.org/cgi/man.cgi?query=poudriere-ports)
for help on how to use `poudriere ports`.

```shell
# Create an empty ports tree, named main
doas poudriere ports -cF -p main
# Check the ports tree that got created
poudriere ports -l
```

#### Setting up portshaker

So now we have a ports tree ready to be consumed by poudriere, but we need to
populate it. I'm using [portshaker](https://github.com/smortex/portshaker) for this.

Thanks Romain for porthshaker, sorry for being that bad at keeping contact :)

##### Creating a ZFS dataset for the portshaker cache

Optionally, it's possible to create a dedicated volume for portshaker cache.
It can be useful if the root ZFS volume is limited in space

```shell
zfs create zroot/portshaker
zfs set mountpoint=/var/cache/portshaker zroot/portshaker
```

##### Configuring the ports trees portshaker will maintain and merge

Shells scripts are used to populate the source ports tree. For more details see
potshaker.d (5)](https://man.freebsd.org/cgi/man.cgi?query=portshaker.d).

As already mentioned, I will need two ports tree sources:

- freebsd: the upstream FreeBSD ports tree
- custom: a git repository where I host the few ports I maintain

For the FreeBSD source, I use the
[official FreeBSD ports GitHub mirror](https://github.com/freebsd/freebsd-ports.git).

Create `/usr/local/etc/portshaker.d/freebsd`:

```shell
#!/bin/sh
. /usr/local/share/portshaker/portshaker.subr
if [ "$1" != '--' ]; then
  err 1 "Extra arguments"
fi
shift
method="git"
git_clone_uri="https://github.com/freebsd/freebsd-ports.git"
git_branch="main"
run_portshaker_command "$@"
```

Make the script executable:

```shell
$ chmod +x /usr/local/etc/portshaker.d/freebsd
```

For the custom source, I will use a public GitHub repositories that I manage:
[gwarf/freebsd-ports-custom](https://github.com/gwarf/freebsd-ports-custom.git).

I'm cloning using `https` and not using `ssh+git` as it's a public repository
and as it is simpler, avoiding the need to care about authentication and
authorization.

In case authentication is required, you will have to ensure the `root` user
can properly authenticate, using a personal authentication token, an SSH key
or else, as supported by the git client.

Create `/usr/local/etc/portshaker.d/custom`:

```shell
#!/bin/sh
. /usr/local/share/portshaker/portshaker.subr
if [ "$1" != '--' ]; then
  err 1 "Extra arguments"
fi
shift
method="git"
git_clone_uri="https://github.com/gwarf/freebsd-ports-custom.git"
git_branch="main"
run_portshaker_command "$@"
```

Make the script executable:

```shell
chmod +x /usr/local/etc/portshaker.d/custom
```

##### Configuring portshaker

The main configuration of [potshaker]() is in
`/usr/local/etc/portshaker.conf`, and an sample file is provided as `/usr/local/etc/portshaker.conf.sample`.
The man page is helpful
[portshaker.conf (5)](https://man.freebsd.org/cgi/man.cgi?query=portshaker.conf).

The goal of this configuration is to populate the `/poudriere/ports` ports
tree that will be used by poudriere.

The `custom` ports tree will be used as an overlay on the offical FreeBSD
ports tree, overwriting existing files, to update existing ports, and adding
new files and directories for adding new ports.

Create `/usr/local/etc/portshaker.conf`:

```shell
# Directory to cache port trees
mirror_base_dir="/var/cache/portshaker"
use_zfs="yes"
# Poudriere-related configuration
poudriere_dataset="zroot/poudriere"
poudriere_ports_mountpoint="/poudriere/ports"
# Merge trees in the empty `main` pourdriere ports tree prepared previously
main_poudriere_tree="main"
# Force overwritting files freebsd ports with custom overlay
# This doesn't remove non matching files
main_merge_from="freebsd custom+"
```

##### Using portshaker

The porthskare UX is quite simple, you will want to often use it without any
parameter, meaning that it will update and merge all trees.

```shell
# Update a single port tree
portshaker -u freebsd
# Update all ports trees
portshaker -U
# Merge prot trees
porthakser -M
# Update and merge port trees
portshaker
```

### Building the ports

I use `/usr/local/etc/poudriere.d/pkglist` to document the list of ports to be
built, let's first populate it:

```shell
# Populating the list of packages to be built
doas echo 'security/rbw' > /usr/local/etc/poudriere.d/pkglist
doas echo 'www/lua-resty-session' >> /usr/local/etc/poudriere.d/pkglist
```

Then it's possible to build the ports with the jail template that was
previously created.

```shell
# Updating and merging the trees
portshaker
# Building packages verbosely using the merged ports trees
doas poudriere bulk -f /usr/local/etc/poudriere.d/pkglist -j 14-1-amd64 -p main -v -v -v
```

The resulting ports will be in `/poudriere/data/packages/14-1-amd64-main/`,
`14-1-amd64` being the name of the jail used to build, and `main` being the
name of the poudriere ports tree.

### Using the ports

It is possible to access the repository locally.

Create repository definition in `/usr/local/etc/pkg/repos/custom.conf`:

```json
Custom: {
  url: "file:////poudriere/data/packages/14-1-amd64-main"
}
```

Use the repository:

```shell
# Update packages list
doas pkg update
# Search for a package, showing its origin
doas search -Q repository rbw
rbw-1.11.1
Repository     : Custom [file:////poudriere/data/packages/14-1-amd64-main]
Comment        : Unofficial Bitwarden cli
```

> It is possible to serve directly or `rsync` this directory to a web server
> so that FreeBSD servers and jails can use it.

### Testing a port in a jail

When working on ports, it's also very convenient to use
[poudiere-testport (8)](https://man.freebsd.org/cgi/man.cgi?query=poudriere-testport)
to test an individual port, before using it, and/or submitting it.

Adding the `-i` paramter will allow to spawn an interactive shell, allowing to
do some changes and tests. As the ports as built as the `nobody` user, it may
be required to excalate to root via `su -`.

```shell
doas poudriere testport -j 14-1-amd64 -p main -o security/rbw
```

## To be followed

While I'm currently very happy with this setup, and all the tools I used,
there are things to improve, like making use of ccache, or customising ports
options.

I also need to find and document a simple/easy way to use poudriere to work on
ports, like when bumping their versions or creating new ones.
I've some notes on waht I currently do, but it's not yet something I'm happy
with.

## References

Here is some documetation I followed to set this up, thanks to all the
authors.

- [FreeBSD Handbook: building packages with poudriere](https://docs.freebsd.org/en/books/handbook/ports/#ports-poudriere)
- [FreeBSD Porter's Handbook: Testing with poudriere](https://docs.freebsd.org/en/books/porters-handbook/testing/#testing-poudriere)
- [GitHub Poudriere wiki: portshaker](https://github.com/freebsd/poudriere/wiki/portshaker)
- [Erwan Martin: Build your own FreeBSD ports and make packages out of them using jails, poudriere and portshaker](https://zewaren.net/poudriere.html)
- [Bert JW Regeer: Building Custom Ports With Poudriere And Portshaker](https://funcptr.net/2013/12/11/building-custom-ports-with-poudriere-and-portshaker/)
- [FreeBSD forum: apply own patches with poudriere"](https://forums.freebsd.org/threads/apply-own-patches-automatically-with-poudriere.46097/)
- [Boris Tassou: FreeBSD: poudriere ou comment gérer ses paquets](https://www.boris-tassou.fr/freebsd-poudriere-ou-comment-gerer-ses-paquets/)
- [Poudriere: Getting Started - Tutorial](https://wiki.freebsd.org/VladimirKrstulja/Guides/Poudriere)
