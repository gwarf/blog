---
title: "Using Nitrokey Pro and Fido2"
date: 2020-07-09T14:36:23+02:00
draft: true
toc: false
images:
tags: 
  - sysadmin
  - linux
  - archlinux
  - security
---

In order to store and protect my credentials and to simplify 2 Factor
authentication I've bought some USB keys from [Nitrokey](https://www.nitrokey.com).

While it may be possible to find more complete or fancy solutions I selected
**Nitrokey**, a German company, as both hardware and software is Open Source
and I trust this way more than a black box provided by a company that is asking
to get some blind trust.

For storing and protecting GPG or S/MIME key I've choosed a [Nitrokey Pro
2](https://www.nitrokey.com/files/doc/Nitrokey_Pro_factsheet.pdf) USB key.

For simplifying authentication I've also selected a [Nitrokey
FIDO2](https://www.nitrokey.com/files/doc/Nitrokey_FIDO2_factsheet.pdf)), it
can be use for passwordless authentication (FIDO2) or as as a second
authentification factor (U2F).

I will be using mainly on my GNU/Linux Archlinux personal desktop and on my
work MacOS X laptop. I may also try it on Windows 10.

I will be using my existing personal GPG key and my work S/MIME certificate
from Sectito and part of the Interoperable Global Trust Federation
[IGTF](https://www.igtf.net/), as since years (decades in fact :) ) an
X509-based Public Key Infrastructure (PKI) is used to identify and authorize
access to the computing and storage resources. More and more services are now
doing Federated authentication via [OpenID
Connect](https://openid.net/connect/) and [SAML
2.0](https://www.oasis-open.org/standards#samlv2.), but
[X509](https://tools.ietf.org/html/rfc5280) certificates will be there for some
more time.
If you want to learn a bit about the European EGI distributed infrastructure
supporting scientific computing you can start at [EGI](https://egi.eu).

My first intent is to make use of the Nitrokey Pro 2 to sign my messages using
mutt (what else?). As said my personal messages are signed using my PGP/GPG
key, and my work emails are signed using my S/MIME certificate.

In case you don't already have a GPG key you can create one on your comupter
and then import it in the Nitrokey, thus allowing you to backup it elsewhere.
Nitrokey provide a clean documentation about [generating your GPG
key](https://www.nitrokey.com/documentation/openpgp-create-backup).
I also put together some notes/links in [a gist](https://gist.github.com/gwarf/e017afb1e627c86d5cf753579cf28b3a).

I also want to use the Nitrokey FIDO2 to protect access to my
[BitWarden](https://bitwarden.com) password manager - BitWarden is similar to
LastPass or 1password, but it's Open Source and you can host the
synchronisation server on premise if needed. I highly recommned using BitWarden
too.

## Using the Nitrokey Pro 2 with S/MIME

According to [Nitrokey Pro 2 documentation for
S/MIME](https://www.nitrokey.com/documentation/smime-email-encryption) it's
required to install [OpenSC](https://github.com/OpenSC/OpenSC).  According to
the [Archlinux wiki](https://wiki.archlinux.org/index.php/Smartcards), **pcsc**
and **ccid** can help.

They can be installed from the community repository:
```sh
❯ trizen -S opensc pcsc-tools ccid
```

Then edit `/etc/opensc.conf` to appen `enable_pinpad = false` in the
configuration block and start `pcscd.service`:
```sh
❯ sudo systemctl start pcscd.service
```

The smart card should show up:
```sh
❯ openpgp-tool -C -K
Using reader with a card: Nitrokey Nitrokey Pro (000000000000000000008016) 00 00
AID:             d2:76:00:01:24:01:03:03:00:05:00:00:80:16:00:00
Version:         3.3
Manufacturer:    ZeitControl
Serial number:   00008016
Aut Algorithm:   RSA4096
Aut Create Date: 2020-07-09 16:39:14
Aut Fingerprint: 9e:4a:04:77:6b:6d:36:36:d9:fc:4b:2e:60:5c:70:11:5e:f0:57:e3
Dec Algorithm:   RSA4096
Dec Create Date: 2020-07-09 16:37:12
Dec Fingerprint: f3:67:ba:47:cd:ed:90:f8:db:c4:ed:1b:14:a2:b2:22:c2:11:ac:0d
Sig Algorithm:   RSA4096
Sig Create Date: 2020-07-09 16:38:47
Sig Fingerprint: 3f:e2:db:50:71:72:15:18:f6:3d:ba:20:e5:4d:4f:bc:01:ce:ba:44
```

You can also scan for the card reader using `pcsc_scan`:
```sh
❯ pcsc_scan
```

Then the key and certificate pair can be copied from the p12 archive containing
the S/MIME certificate to the key:
```sh
❯ pkcs15-init --delete-objects privkey,pubkey --id 3 --store-private-key baptiste_grenier_until_2021_02.p12[0/3084]t pkcs12 --auth-id 3 --verify-pin
Using reader with a card: Nitrokey Nitrokey Pro (000000000000000000008016) 00 00
User PIN required.
Please enter User PIN [Admin PIN]:
Deleted 2 objects
error:23076071:PKCS12 routines:PKCS12_parse:mac verify failure
Please enter passphrase to unlock secret key:
Importing 1 certificates:
  0: /DC=org/DC=terena/DC=tcs/C=NL/O=Stichting EGI/OU=Operations/CN=Baptiste Grenier
❯ pkcs15-init --delete-objects privkey,pubkey --id 2 --store-private-key baptiste_grenier_until_2021_02.p12 --format pkcs12 --auth-id 3 --verify-pin
Using reader with a card: Nitrokey Nitrokey Pro (000000000000000000008016) 00 00
User PIN required.
Please enter User PIN [Admin PIN]:
Deleted 2 objects
error:23076071:PKCS12 routines:PKCS12_parse:mac verify failure
Please enter passphrase to unlock secret key:
Importing 1 certificates:
  0: /DC=org/DC=terena/DC=tcs/C=NL/O=Stichting EGI/OU=Operations/CN=Baptiste Grenier
Failed to store private key: Not supported
```

According to the Nitrokey documentation the errors can be ignored.

### Using neomutt with S/MIME certificate on the Nitrokey Pro 2

## Using the Nitrokey Pro 2 with GPG/PGP

### Preparing the GPG keys

By security I will not keep the master key on the Nitrokey, but store 3
different secret subkeys each limited to a specific usage.
This will allow to manage them individually.
- one for signing
- one for encrypting
- one for authenticating

The master secret key should be exported and deleted from local keyring and
saved in a secure location (or even multiple secure locations).

### Setup on Archlinux

As per [Nitrokey
documentation](https://www.nitrokey.com/documentation/installation#p:nitrokey-pro&os:linux)
`libccid` is used to interact with the OpenPGP smart card in the Nitrokey.

It doesn't seem to be available by default in Archlinux, but searching the
repositories using [trizen]() I found some nitrokey stuff:

```sh
❯ trizen -Ss nitrokey
extra/libnitrokey 3.5-2
    Communicate with Nitrokey stick devices in a clean and easy manner
extra/nitrokey-app 1.4-2
    Nitrokey management application
aur/libnitrokey-git 3.4.1r781.ef171df-1 [unmaintained] [1+] [0.00%] [21 Aug 2018]
    Communicate with Nitrokey stick devices in a clean and easy manner
aur/nitrocli 0.3.1-1 [2+] [0.00%] [4 Jan 2020]
    Command-line interface for Nitrokey devices
```

So I installed and gave a try at `nitokey-app` that seems to be an official
application by Nitrokey folks, versions for the various OS can be found on
[their website](https://www.nitrokey.com/download).

Forward future jump: in fact it's possible to do everything using `gpg`.

The first step si to **Configure** it by **Changing the User and Admin PINs**.
For reference default User PIN is 123456, and Default Admin PIN is 12345678.

It can be done from the Menu of the [Nitrokey
App](https://www.nitrokey.com/documentation/change-user-and-admin-pin).

As said I'm using BitWarden so I will generate and store the PINs in BitWarden,
as it's always handy to be able to check the PIN there before locking the
Nitrokey at the 3rd failed unlocking tentative.

Once the PINs have been replaced, the next step is importing the GPG keys in
the Nitrokey Pro 2.

```sh
# Once plugged the key should show be available to gpg
❯ gpg --card-status
Application type .: OpenPGP
Version ..........: 3.3
Manufacturer .....: ZeitControl
(...)
Name of cardholder: [not set]
Language prefs ...: de
Salutation .......:
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: forced
Key attributes ...: rsa2048 rsa2048 rsa2048
Max. PIN lengths .: 64 64 64
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

Let's configure the card, you should be asked for the Admin PIN when updating
the information:

```sh
❯ gpg --card-edit

gpg/card> admin
Admin commands are allowed

gpg/card> name
Cardholder's surname: Baptiste
Cardholder's given name: Grenier

gpg/card> sex
Salutation (M = Mr., F = Ms., or space): M

gpg/card> lang
Language preferences: fr

gpg/card> key-attr
Changing card key attribute for: Signature key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 4096
The card will now be re-configured to generate a key of 4096 bits
Changing card key attribute for: Encryption key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 4096
The card will now be re-configured to generate a key of 4096 bits
Changing card key attribute for: Authentication key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 4096
The card will now be re-configured to generate a key of 4096 bits

gpg/card> list

Reader ...........: 20A0:4108:000000000000000000008016:0
Application ID ...: D2760001240103030005000080160000
Application type .: OpenPGP
Version ..........: 3.3
Manufacturer .....: ZeitControl
Serial number ....: 00008016
Name of cardholder: Grenier Baptiste
Language prefs ...: fr
Salutation .......: Mr.
URL of public key : https://keys.bapt.name/pubkey.asc
Login data .......: [not set]
Signature PIN ....: forced
Key attributes ...: rsa4096 rsa4096 rsa4096
Max. PIN lengths .: 64 64 64
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]

gpg/card> quit
```

Let's now add the three subkeys. As you can see from the following output, I've
got one master key, that is only used to manage the secret subkeys and that is
ideally meant to be kept offilne at a secure place, and 3 secret subkeys that
are used for only one purpose: (E)ncrypting, (S)igning and (A)uthenticating.

```sh
❯ gpg --edit-key --expert 0xCDA18F02
gpg (GnuPG) 2.2.20; Copyright (C) 2020 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Secret key is available.

sec  rsa4096/022A860ECDA18F02
     created: 2019-04-19  expires: never       usage: SC
     trust: ultimate      validity: ultimate
ssb  rsa4096/14A2B222C211AC0D
     created: 2020-07-09  expires: never       usage: E
ssb  rsa4096/E54D4FBC01CEBA44
     created: 2020-07-09  expires: never       usage: S
ssb  rsa4096/605C70115EF057E3
     created: 2020-07-09  expires: never       usage: A
[ultimate] (1). Baptiste Grenier <baptiste@bapt.name>
[ultimate] (2)  Baptiste Grenier (EGI) <baptiste.grenier@egi.eu>
[ultimate] (3)  Baptiste Grenier <gwarf@gwarf.org>

# Select the first key that will be used for (E)ncryption
gpg> key 1

gpg> keytocard
Please select where to store the key:
   (2) Encryption key
Your selection? 2

# Provide the GPG key passphrase to unlock the gpg secret sub key
# Provide the Nitrokey Administrator PIN code

# Then use the key command to select the key for (S)igning (this command is
# used to toggle selection of a key, beware of not having multiple keys
# selected together) enable the second key
# Deselect key 1
gpg> key 1

# Select key 2
gpg> key 2

gpg> keytocard
Please select where to store the key:
   (1) Signature key
   (3) Authentication key
Your selection? 1

# Finally do the same thing for the authentication key
# used to toggle selection of a key, beware of not having multiple keys
# selected together) enable the second key

# Deselect key 2
gpg> key 2

# Select key 3
gpg> key 3

gpg> keytocard
Please select where to store the key:
   (3) Authentication key
Your selection? 3

# The save
gpg> save
```

Check the status of the nitrokey in another terminal:
```sh
❯ gpg --card-status

Reader ...........: 20A0:4108:000000000000000000008016:0
Application ID ...: D2760001240103030005000080160000
Application type .: OpenPGP
Version ..........: 3.3
Manufacturer .....: ZeitControl
Serial number ....: 00008016
Name of cardholder: Grenier Baptiste
Language prefs ...: fr
Salutation .......: Mr.
URL of public key : https://keys.bapt.name/pubkey.asc
Login data .......: [not set]
Signature PIN ....: forced
Key attributes ...: rsa4096 rsa4096 rsa4096
Max. PIN lengths .: 64 64 64
PIN retry counter : 3 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: 3FE2 DB50 7172 1518 F63D  BA20 E54D 4FBC 01CE BA44
      created ....: 2020-07-09 16:38:47
Encryption key....: F367 BA47 CDED 90F8 DBC4  ED1B 14A2 B222 C211 AC0D
      created ....: 2020-07-09 16:37:12
Authentication key: 9E4A 0477 6B6D 3636 D9FC  4B2E 605C 7011 5EF0 57E3
      created ....: 2020-07-09 16:39:14
General key info..: sub  rsa4096/E54D4FBC01CEBA44 2020-07-09 Baptiste Grenier <baptiste@bapt.name>
sec   rsa4096/022A860ECDA18F02  created: 2019-04-19  expires: never
ssb>  rsa4096/14A2B222C211AC0D  created: 2020-07-09  expires: never
                                card-no: 0005 00008016
ssb>  rsa4096/E54D4FBC01CEBA44  created: 2020-07-09  expires: never
                                card-no: 0005 00008016
ssb>  rsa4096/605C70115EF057E3  created: 2020-07-09  expires: never
                                card-no: 0005 00008016
```

#### Usage with neomutt

TBD

### Usage on MacOS X

### Usage on Windows 10

## 2 Factor authentication with the FIDO U2F

### 2FA for BitWarden

Using 2FA with BitWarden is quite straightforward as it's documented [in the
official BitWarden
documentation](https://bitwarden.com/help/article/setup-two-step-login-u2f/).
Basically the Nitrokey FIDO2 key can be registered to your account, and will
only have to be connected.

As always it's always better to always keep mutliple possibilities for doing
second factor authentication, like a One Time Password (OTP) generated by an
authentification application such as Authy or Google Authenticator.

## Documnentation

- [Nitrokey](https://www.nitrokey.com)
- [Nitrokey documentation](https://www.nitrokey.com/documentation/installation)
- [FIDO2]()
- [U2F]()
- [IGTF](https://www.igtf.net/)
- [Nitokey + GPG usage by Raymii](https://raymii.org/s/articles/Nitrokey_Start_Getting_started_guide.html)
- [Nitorkey +GPG usage in French by ephase](https://xieme-art.org/post/importer-des-clefs-gnupg-dans-sa-nitrokey-pro/)
