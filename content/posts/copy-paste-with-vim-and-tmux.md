---
title: "Copy Paste With Vim and Tmux"
date: 2020-04-28T11:07:46+02:00
draft: true
---

## Copying between two VIM sessions

Using vim + clipboard copy to just get vim content and not all the VIM
formatting (line numbers and so on).

- On MacOS X `+` and `*` registers are the same.
- On GNU/Linux

  - `+` is the desktop clipboard (usable via ctl-c/x/v)
  - `*` is the X11 primary selection (usable via mouse selection/middle mouse button)

- Select text in VIM
- Copy to the * register (system clipboard) `"*y`
- Paste the clipboard in new vim session `"*p`

## Copying using TMUX

- https://github.com/tmux-plugins/tmux-copycat
- https://github.com/tmux-plugins/tmux-yank
- https://vim.fandom.com/wiki/Accessing_the_system_clipboard
