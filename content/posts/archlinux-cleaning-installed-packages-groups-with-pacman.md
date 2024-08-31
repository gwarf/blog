---
title: "Archlinux cleaning installed packages groups with Pacman"
date: 2020-05-01T10:37:52+02:00
toc: false
images:
tags: 
  - sysadmin
  - archlinux
---

On [Archlinux](https://archlinux.org)
[pacman](https://wiki.archlinux.org/index.php/Pacman) allows to install
packages as a group.
Cleaning those packages and their dependencies is not as straight forward, but
it possible to do cleaning by using a few commands.

Here let's try to clean plasma stuff (finally I find gnome more straightforward
to used, despite being sometimes a bit surprised by the lack of customisation
or by some choices.)

```sh
# Check installed packages from groups
pacman -Qg
# Collect installed list of packages for specific groups
pacman -Qgq plasma > plasma.txt
pacman -Qgq qt >> plasma.txt
pacman -Qgq qt5 >> plasma.txt
pacman -Qgq kf5 >> plasma.txt
pacman -Qgq kf5-aids >> plasma.txt
pacman -Qgq kde-applications >> plasma.txt
# Clean list of package if needed
vim plasma.txt
# Delete the packages and the ones that requires them
# XXX double check what is/will be deleted an reinstall what as needed
sudo pacman -Rc - < plasma.txt
# Reinstall what is still being used
sudo pacman -S nextcloud-client vlc virtualbox qgpgme
```

Side note: I'm usually using [trizen](https://github.com/trizen/trizen) to
manage packages and AUR at once.
