---
title: "Hacking Cheatsheet"
date: 2020-04-14T12:51:06+02:00
toc: false
images:
tags:
  - hacking
---

Some notes while doing some CTF.

## Collecting information about an IP

- [Shodan](https://shodan.io)
- [anti-hacker-alliance.com](https://anti-hacker-alliance.com)

## Port scan with nmap

```sh
sudo nmap -sC -sV -oA outputfile $IP
```

## Web inventory

### Searching for webdirectories

```sh
gobuster dir -u http://oouch.htb:5000/ \
  -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt \
  | tee gobuster-directories.txt
```

### Searching for domain names

```sh
gobuster vhost -u http://oouch.htb:5000/ \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  | tee gobuster-vhosts.txt
wfuzz  --hh 0 --hc 302 \
  -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt \
  -H 'Host: FUZZ.oouch.htb' -u http://oouch.htb:5000/
```
