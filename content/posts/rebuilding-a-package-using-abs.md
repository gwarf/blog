+++
title = "rebuilding a package using abs"
date = "2014-07-29"
slug = "2014/07/29/rebuilding-a-package-using-abs"
Categories = []
+++
# Rebuilding an Archlinux package using Arch Build System (ABS)

Rebuilding a system package on Archlinux as a user is really simple using
[ABS](https://wiki.archlinux.org/index.php/Arch_Build_System)

``` sh
yaourt -S abs
cp /etc/abs.conf ~/.abs.conf
sed -i 's#.*ABSROOT.*#ABSROOT="\$HOME/abs"#' ~/.abs.conf
mkdir ~/abs
abs extra/nvidia
cd ~/abs/extra/nvidia
makepkg -s
yaourt nvidia*.pkg.tar.xz
```
