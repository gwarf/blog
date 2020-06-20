---
title: "Avoiding Spam Classification When Sending Mail DMARC DKIM SPF"
date: 2020-06-20T11:19:29+02:00
draft: true
toc: false
images:
tags: 
  - untagged
---

# Debug email

Example setup (my setup):

- One mailserver for multiple domains (using mailcow)
  - Mail server (MX): mail.bapt.name
  - Domain configured on the MX: bapt.name, debiocidons.fr and badoulin.fr
- DMARC configuration centralized on the bapt.name domain (other domains using CNAME to point to it)

## About SPF

TBD
- http://www.open-spf.org/SPF_Record_Syntax/

## About DKIM

TBD

## About DMARC

- https://dmarc.org/
- https://tools.ietf.org/html/rfc7489
- https://datatracker.ietf.org/wg/dmarc/documents/

## About BIMI

TBD
- https://authindicators.github.io/rfc-brand-indicators-for-message-identification/

## Testing configuration

### Mail tester

https://www.mail-tester.com

### Mxtoolbox

- https://mxtoolbox.com/
- https://mxtoolbox.com/SuperTool.aspx?action=dmarc%3abadoulin.fr&run=toolpage

### dmarcian

- https://dmarcian.com/dmarc-inspector/
- https://dmarcian.com/dmarc-inspector/?domain=debiocidons.fr
- https://dmarcian.com/dmarc-inspector/?domain=badoulin.fr
- https://dmarcian.com/dmarc-inspector/?domain=bapt.name

### DMARC Analyzer

- https://www.dmarcanalyzer.com/dmarc/dmarc-record-check/

## DMARC configuration on bapt.name

- https://www.agari.com/email-security-blog/pros-cons-dmarc-reject-vs-quarantine/
- https://dmarcian.com/rua-vs-ruf/

Put mails not passing the DMARC check in quarantine (likely to go to be marked as spam, but not rejected.)

```
 _dmarc.bapt.name. TXT v=DMARC1;p=quarantine;rua=mailto:baptiste@bapt.name;ruf=mailto:baptiste@bapt.name;
```

### Reporting errors for badoulin.fr and debiocidons.fr to bapt.name

- https://dmarc.org/2015/08/receiving-dmarc-reports-outside-your-domain/

Authorisation should be configured in bapt.name DNS zone:

```
Type: TXT
Host/Name: badoulin.fr._report._dmarc.bapt.name
Value: v=DMARC1
```

### Pointing to the DMARC configuration of another domain

On badoulin.fr:

```
Type: CNAME
Host/name: _dmarc.badoulin.fr.
Value: _dmarc.bapt.name.
```

## Fixing problems with email providers refusing emails

- Postmaster free: https://postmaster.free.fr
- Postmaster laposte.net: https://postmaster.laposte.net
