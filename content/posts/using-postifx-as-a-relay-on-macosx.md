---
title: "Using Postifx as a Relay on MacOS"
date: 2020-04-21T14:53:58+02:00
draft: true
---

## Local Postfix relying to Google's SMTP server

The intent is to use the `postfix` system install to relay email to Google's
SMTP server.

## Configure mail aliases

`/etc/aliases` is a symlink to `/etc/postfix/aliases`, it can be updated to
redirect `root` or any other user's email to another address:

```mailaliases
root: my.email@domain.tld
userX: my.email@domain.tld
```

Aliases database should updated:

```sh
sudo postalias /etc/postfix/aliases
```

## Altering postfix configuration

`/etc/postfix/main.cf` should be tuned:

```ini
myhostname = Baptistes-MacBoo-Pro.local
(...)
# inet_protocols = all
(...)
# https://www.howtoforge.com/tutorial/configure-postfix-to-use-gmail-as-a-mail-relay/
# https://www.justinsilver.com/technology/osx/send-emails-mac-os-x-postfix-gmail-relay/
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtpd_sasl_auth_enable = yes
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_use_tls=yes
smtp_tls_security_level=encrypt
tls_random_source=dev:/dev/urandom
smtp_sasl_security_options =
smtp_sasl_mechanism_filter = AUTH LOGIN
inet_protocols = ipv4
virtual_alias_maps = hash:/etc/postfix/virtual
```

## Adding virtual entries

In order to map local address to fully qualified address, `/etc/postfix/virtual`
should be updated:

```raw
baptiste my.email@domain.tld
baptiste@Baptistes-MacBook-Pro.local my.email@domain.tld
```

Then the virtual map should be updated

```sh
sudo postmap /etc/postfix/virtual
```

## Starting the local postfix as a daemon

```sh
sudo postfix start
```

## Checking postfix logs

```sh
log stream --predicate '(process == "smtpd") \
  || (process == "smtp") \
  || (process == "master")' --info
```

## Checking conf after a MacOS update

When MacOS gets updated it can alter the configuration changes and revert to
default settings or let you review the changes they made to the default
configuration files. You can check any `~orig` files having been created under
`/etc/postfix` as well as default files ending in `_default` available under
`~/Desktop/Relocated Items/Configuration`.

### Links

- https://knazarov.com/posts/setting_up_postfix_on_os_x/
- https://www.garron.me/en/mac/postfix-relay-gmail-mac-os-x-local-smtp.html
- https://www.linode.com/docs/email/postfix/postfix-smtp-debian7/
- https://www.howtoforge.com/tutorial/configure-postfix-to-use-gmail-as-a-mail-relay/
- https://benjaminrojas.net/configuring-postfix-to-send-mail-from-mac-os-x-mountain-lion/
- https://www.cmsimike.com/blog/2011/10/30/setting-up-local-mail-delivery-on-ubuntu-with-postfix-and-mutt/
- https://discussions.apple.com/thread/8594103
- https://www.justinsilver.com/technology/osx/send-emails-mac-os-x-postfix-gmail-relay/
- https://unix.stackexchange.com/questions/128004/mutt-not-sending-email-when-specifying-smtp-server
- https://www.garron.me/en/mac/postfix-relay-gmail-mac-os-x-local-smtp.html
- https://annvix.com/using_mutt_on_os_x
- https://knazarov.com/posts/setting_up_postfix_on_os_x/
  https://www.cryptomonkeys.com/2015/09/mutt-and-msmtp-on-osx/
