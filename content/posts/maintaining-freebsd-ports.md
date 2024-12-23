---
title: "Maintaining Freebsd Ports"
date: 2024-09-15T11:35:41+02:00
toc: true
tags:
  - freebsd
  - tutorial
  - ports
  - maintainer
---

> Post covering how to maintain FreeBSD ports.

## My requirements - wishes

- Building in a clean environement with usolation from the host system
- Being able to work as a non privileged user as much as possible
- Having clear and simple worfklow to:
  - Create new ports
  - Update existing ports

## Tooling

> See [Building FreeBSD ports]({{< ref "building-freebsd-ports.md" >}}).

## Setting the tools up

I will make use of [doas](https://man.freebsd.org/cgi/man.cgi?query=doas)
to run the commands as root.

```shell
# All my git repositories are kept under ~/repos
cd ~/repos

# Clone official FreeBSD port tree
git clone https://git.FreeBSD.org/ports.git freebsd-ports
# Create a work ports tree
doas poudriere ports -c -m null -M /home/baptiste/repos/freebsd-ports -p work

# create a new local overlay to use in poudriere when creating ports
git clone git@github.com:gwarf/freebsd-ports-custom.git
doas poudriere ports -c -m null -M /home/baptiste/repos/freebsd-ports-custom -p custom

# Check existing port trees
doas ports -l
 
# Setup work env to point to local clone
export PORTSDIR=~/repos/freebsd-ports
export DISTDIR=$PORTSDIR/distfiles
export PORT_DBDIR=~/var/db/ports

# Create a branch or checkout existing one to work with
cd $PORTSDIR
doas git branch rbw
doas git checkout -b rbw

# Copy files from the port overlay
diff -ur ~/repos/freebsd-ports-custom/security/rbw $PORTSDIR/security/rbw
cp -rv ~/repos/freebsd-ports-custom/security/rbw $PORTSDIR/security/

# Open port work directory
cd $PORTSDIR/security/rbw

# Do work to create or update the port
# Edit the Makefile, bump version and so on
vim Makefile
# Update distfiles and checksums
make makesum

# Run additional specific steps

## Go-related changes, refer to:
# https://github.com/freebsd/freebsd-ports/blob/main/Mk/Uses/go.mk
# https://docs.freebsd.org/en/books/porters-handbook/uses/#uses-go
# https://docs.freebsd.org/en/books/porters-handbook/special/#using-go
# Upate go depencencies
make gomod-vendor > Makefile.deps.new
# Copy changes, omitting changes on dexidp:dex (to be confiremd) 
vimdiff Makefile.deps.new Makefile.deps
# Do changes as needed if next commands encoutner errors
# It may be required to fix some versions
# looking at the proper version info at the upstream repos, ex:
# https://github.com/open-telemetry/opentelemetry-go-contrib/releases
# https://github.com/googleapis/google-cloud-go/releases?expanded=true&page=4&q=compute
# https://github.com/search?q=repo%3Afreebsd%2Ffreebsd-ports
# Update distfiles checksums for go modules
# Update distfiles checksums for go modules
make makesum

## rust-related changes
# Update cargo crates
make cargo-crates >> Makefile
# Merge cargo-crates update
# Check if plist changed
make makeplist
# Lint port
portlint -A

# Test using poudriere testport, and our work port tree
doas poudriere testport -j 14-1-amd64 -p work -o security/rbw
# If failing, it's possible to launch an interactive session
doas poudriere testport -j 14-1-amd64 -p work -o security/rbw -i -v -v

# Once test are OK, publish changes back to the cust port overlay
# Clean port work directory once finalised
make clean
diff -ur $PORTSDIR/security/rbw ~/repos/freebsd-ports-custom/security/rbw
cp -rv $PORTSDIR/security/rbw ~/repos/freebsd-ports-custom/security/

# Commit changes to the work branch
doas git add .
doas git status
doas git commit -am 'Bump rbw to 1.12.1'

# Create a patch
doas git format-patch origin/main

# Switch back to main branch
doas git checkout main
doas git pull

# Rebase rbw work branch from main to get latest changes
doas git pull rebase origin/main rbw
```

## Update rbw version and send a new patch

```shell
cd ~/repos/freebsd-ports-custom/security/rbw
# Update version
vim Makefile

# Review and commit changes
git commit -am 'Update rbw to 1.12.1'
# Push changes remotely
git push
# Update and merge portshaker repositories
doas portshaker
# Test updated port, moving to interactive use to be able to update the Makefile
doas poudriere testport -j 14-1-amd64 -p main -o security/rbw -i
su -
# Update cargo crates
#FIXME: this reports issues
# Not validating first entry in CATEGORIES due to being outside of PORTSDIR.
make cargo-crates >> Makefile
# Merge cargo-crates update
vim Makefile
# Update sums
make makesum
#XXX: get changes from the jail to update the ports tree outside of the Jail

# Push changes to customised branch
cd ~/repos/freebsd-ports/security/rbw/
cp -rv ~/repos/freebsd-ports-custom/security/rbw/* .

# Commit changes to rbw branch or to a new branch
git fetch
git rebase origin/main rbw
# Squash changes if the updated port is not yet in the tree
git rebase -i ...
# Review changes
git diff origin/main
# Create a patch
git format-patch origin/main
```

## Make a patch to send to bugzilla

```shell
cd ~/repos/freebsd-ports
# Update main branch
git checkout main
git pull
# Create a new branch
git checkout -b rbw
# Rebase the branch for main if it was already created
git rebase origin/main rbw
# Add changes from personal repo
cp -riv ~/repos/freebsd-ports-custom/security/rbw  ~/repos/freebsd-ports/security/ 
# Commit changes
git add security/rbw
git commit -am 'Add rbw port'
# Create a patch from origin
git format-patch origin/main
# Propose 0001-Add-rbw-port.patch via bugzilla
```

## To be followed

- Submit update using a PR in GitHub

## References

Here is some documentation I followed to set this up, thanks to all the
authors.

- https://people.freebsd.org/~olivierd/porters-handbook/testing-poudriere.html
- https://wiki.freebsd.org/VladimirKrstulja/Guides/DevelopingPorts
- https://forums.freebsd.org/threads/diy-upgrade-of-i386-wine-amd64-package-with-poudriere.79570/
- https://medium.com/@andoriyu/this-is-how-you-can-port-your-rust-application-to-freebsd-7d3e9f1bc3df
