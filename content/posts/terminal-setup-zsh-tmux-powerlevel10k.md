---
title: "Terminal setup ZSH tmux powerlevel10k"
date: 2020-04-25T17:51:44+02:00
draft: false
toc: false
images:
tags: 
  - unixporn
  - terminal
  - zsh
  - tmux
  - macosx
  - iterm2
  - gnome-terminal
  - powerlevel10k
  - hack-nerd-font
  - neovim
---

Today I was contacted by a person asking for my terminal setup, after having
seen it in [a GitHub issue](https://github.com/aristocratos/bashtop/issues/25).

So even if most of my conf is already available in my
[dotfiles](https://github.com/gwarf/dotfiles) let's share it here too in a more
documented way, maybe someone may be interested by this too.

Obviously it's for ZSH not bash. :P

Please also be waned that my dotfiles are a work in progress and quite
messy/broken, some stuff are also quite obsolete.

So what was shown was my MacOS X setup, using iterm2 with the [nord theme](https://www.nordtheme.com/), ZSH and
true colors:

![Screenshot 2020-04-24 at 15 37 34](/blog/iterm2-powerlevel10k.png)

## Terminal: iTerm2 or gnome-terminal with Hack Nerd font

- The MacOS X terminal is iTerm2: https://iterm2.com/
- The iTerm2 theme is Nord: https://github.com/arcticicestudio/nord-iterm2
- The font is Hack Nerd: https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Hack

On GNU/Linux I'm using gnome-terminal instead of iTerm2, there is also a Nord
theme for it: https://github.com/arcticicestudio/nord-gnome-terminal

## Shell: ZSH with zplug and powerlevel10k

The shell is Zsh and I'm using Zplug to manage my ZSH conf: https://github.com/zplug/zplug.

The ZSH theme is powerlevel10k: https://github.com/romkatv/powerlevel10k
Powerlevel10k will launch a wizard to help you configuring it, my
configuration file (you can see the options I selected at the top) is:
https://github.com/gwarf/dotfiles/blob/master/p10k.zsh

And my current ZSH conf is
https://github.com/gwarf/dotfiles/blob/master/zsh/zsh-zplug-mac

## Terminal multiplexer: tmux with tmux-nord and tpm

I'm also using tmux https://github.com/tmux/tmux/ with a Nord theme:
https://github.com/arcticicestudio/nord-tmux

My tmux plugins are configured via tpm: https://github.com/tmux-plugins/tpm
My tmux conf is: https://github.com/gwarf/dotfiles/blob/master/tmux.conf

## Text editor: neovim with vim-plug, nord theme and too many things

- My beloved text editor is neovim: https://neovim.io/
- I'm using the vim Nord theme: https://github.com/arcticicestudio/nord-vim
