---
title = "mail server migration"
date = "2014-01-18"
slug = "2014/01/18/mail-server-migration"
Categories = []
---

## Goal

Migrating a mail server from one server (FreeBSD physical server) to another
one (Debian virtual machine) without loosing mails.

## Mail server

### Retrieving mails from other email providers

- fetchmail (cron)

```sh
crontab -e
*/3 * * * * $HOME/bin/getmymailnow > /dev/null
```

`~/bin/getmymailnow`:

```sh
#!/bin/sh
LOCKFILE="$0.lock"
PATH="/bin:/usr/bin"

if [ -f "$LOCKFILE" ]; then
  PID=$(cat "$LOCKFILE")
  if ! ps $PID 2> /dev/null; then
    echo "Ignoring stalled lock file" >&2
  else
    echo "Script already running (PID=$PID)" >&2
    exit 1
  fi
fi

fetchmail -a -s -m "procmail -d %T" 2>&1

echo $! > $LOCKFILE
wait
rm "$LOCKFILE"

exit 0
```

### Tools used for local/virtual mail handling

- Postfix
- Dovecot
- Spamassassin
- roundcube
- procmail
- fetchmail
- bind

## Initial step

- Create required users on new server
- Configure postfix on new server as it was on old one
  - remove mail domain from mydestination to old server
  - set relayhost to old server

- If different domain should be relayed to different places:

```sh /etc/postfix/main.cf
transport_maps = hash:/etc/postfix/transport_maps
```

```sh /etc/postfix/transport_maps
domain.tld smtp:[mail.plop.tld]
```

```sh
postmap /etc/postfix/transport_maps
service postfix restart
```

- Update MX in DNS conf to use new server

All mails should now go to new server, and this one will relay mails to old server.

- Install dovecot on new server
- Migrate and update conf, see [upgrading dovecot](http://wiki2.dovecot.org/Upgrading/2.0)
- Migrate/update required certificates
- Make an initial copy of the mailstores to the new server using rsync

```sh
rsync -avz --stats ~plop/Maildir -e ssh plop@new.server.tld:
```

- Validates that imap/dovecot is working as expected

```sh
openssl s_client -connect new.server.tld:993
a01 login plop the_PassWord
a02 SELECT INBOX
a03 logout
```

- Copy spamassassin conf (global/local) to new server (and review it)
- Copy procmailconf to new server (and review it)
- Copy fetchmail conf (global/local) to new server (and review it)

- Install postgresql on new server
- Migrate roundcube postgres database/user
  - Database dump have to be updated as postgres user name is different

```sh
sed -i 's/pgsql/postgres/g' roundcube.sql
```

- Install roundcube on new server
- Update roundcube conf
- Validate that roundcube is working as expected

- Wait at least a week to ensure that DNS will be up-to-date with new MX (and
  check that you have a small DNS TTL)
- Update DNS entries for SPF

## Final step - including small downtime

- Stops email fetching on old server
- Stops postfix on old server
- Stops dovecot on old server
- Stops roundcube vhost on old server
- Make an incremental copy of the mailstores, deleting no more present emails using rsync

```sh
rsync -avz --delete-after --stats ~plop/Maildir -e ssh plop@new.server.tld:
```

- Configure postfix on new server:
  - disable relaying to old server
  - fix mydestination
- Switch IPs (or hostnames if not possible) to new server
- Update required hostnames in new server
- Update roundcube postgres database
- Enable email fetching on new server
- Configure postfix on old server to relay mails to new server
- Clean old server
- Clean DNS conf

No emails should be lost as if the server is not available, the contacting
servers should hold and resend the mails.
