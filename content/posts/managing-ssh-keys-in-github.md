---
title: "Managing Ssh Keys in Github"
date: 2020-07-22T11:44:47+02:00
draft: true
---

## Storing SSH keys in GitHub

- https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh
- https://docs.github.com/en/github/authenticating-to-github/reviewing-your-ssh-keys

## Retrieving SSH keys from GitHub and checking the fingerprints

```sh
wget https://github.com/gwarf.keys
ssh-keygen -l -E md5 -f gwarf.keys
```
