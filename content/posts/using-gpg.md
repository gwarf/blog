---
title: "Using Gpg"
date: 2020-04-27T10:50:37+02:00
draft: true
---

Notes about using GPG. More questions than answers.

## Setting up GPG

To be documented

## Using GPG in mutt/neomutt

## Checking and trusting keys

- http://keys.gnupg.net/
- http://keys.gnupg.net/pks/lookup?op=vindex&fingerprint=on&search=0x022A860ECDA18F02
- https://pgp.mit.edu/ # Broken?

- Need to mark public key as trusted
  - Always have to do it manually, even if already done and published?
- Fixing "WARNING: We have NO indication whether the key belongs to the person named as shown above" in neomutt

```sh
gpg --receive-keys $EMAIL
gpg --edit-key $EMAIL
gpg> trust
```

## References

- https://serverfault.com/questions/569911/how-to-verify-an-imported-gpg-key
- https://www.liquidweb.com/kb/how-do-i-use-gpg/
