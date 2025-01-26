---
title: "Using Caddy to Serve Poudriere"
date: 2024-08-31T19:52:09+02:00
---

> Follow up to the post [on building FreeBSD ports](../posts/building-freebsd-ports.md).

Poudriere generates HTML content that can be served, and allowing to have an
overview of what is currently happening. It's also handy for digging into
logs.

Poudriere comes with some web server templates that can be used, see
`/usr/local/share/examples/poudriere/` one of them
is for [caddy](https://caddyserver.com/) and allows having a very quick and
simple setup, with even some https on localhost.

## Installing Caddy

Caddy is available as a port, and will run as non root, as documented at
https://wiki.freebsd.org/ThomasHurst/Caddy.

```shell
doas pkg install caddy
doas service enable caddy
doas sysrc caddy_user=www caddy_group=www
doas pkg install portacl-rc
doas sysrc portacl_users+=www
doas sysrc portacl_user_www_tcp="http https"
doas sysrc portacl_user_www_udp="https"
doas service enable portacl
doas service start portacl
doas service start caddy
```

## Configuring Caddy

Caddy will only serve a single host, this I will replace the existing
configuration.

There is also a sample configuration at `/usr/local/etc/caddy/Caddyfile.sample`.

```shell
doas cp /usr/local/share/examples/poudriere/Caddyfile.sample /usr/local/etc/caddy/Caddyfile
```

Edit `/usr/local/etc/caddy/Caddyfile`, to adjust the path to Poudriere, if
needed. In my previous post I used `/poudriere` as `BASEFS`, thus I should
replace `/usr/local/poudriere/data/` as `/poudriere/data/`.
I will also set the host name to `poudriere.local`, and allow to access the
repository via `http`, to be used only on the internalnetwork.
An `https` is also in place, but it's using a Caddy's generated CA, that won't
be trusted by default by other systems.
In a production environment, a real certificate will be used, and if the
servie is publicly reachable, and DNS correctly configured, caddy will
automatically retrieve a Let's Encrypt certificate.

The resulting file, with stripped comment is:

```text
http://poudriere.local, https://poudriere.local {
  root * /usr/local/share/poudriere/html
  file_server
  # This is to access poudriere logs
  handle_path /data/* {
    root * /poudriere/data/logs/bulk/
    file_server browse
    @skiplog_files path_regexp \.json$
    @public_files path_regexp \.(css|gif|html|ico|jp?g|js|png|svg|woff)$
    @recheck_files path_regexp \.(json|log|txz|tbz|bz2|gz)$
    header @recheck_files +Cache-Control "public, must-revalidate, proxy-revalidate"
    skip_log @skiplog_files
    header @public_files +Cache-Control "public, max-age=172800"
    handle_path /logs/* {
      root * /poudriere/data/logs/bulk/
      file_server browse
    }
    handle_path /latest-per-pkg/* {
      root * /poudriere/data/logs/bulk/latest-per-pkg/
      file_server browse
    }
    encode {
      gzip 6
      minimum_length 1100

      # Allow gzipping js, css, log, svg and json files
      match {
        header Content-Type application/atom+xml*
        header Content-Type application/json*
        header Content-Type application/javascript*
        header Content-Type application/rss+xml*
        header Content-Type application/x-javascript
        header Content-Type application/xhtml+xml*
        header Content-Type application/xml*
        header Content-Type image/gif
        header Content-Type image/jpeg
        header Content-Type image/png
        header Content-Type image/svg+xml*
        header Content-Type text/*
      }
    }
  }
  # This is to access the package repository
  handle_path /data/* {
    root * /poudriere/data/packages
    file_server browse
  }
}
```

Start Caddy manually as it's not expected to be used all the time:

```shell
# Start caddy manually
doas service caddy restart
```

The Caddy logs are in `/var/log/caddy/caddy.log`.

Then open [https://poudriere.local](https://poudriere.local), and accept the certificate.

## Configuring a FreeBSD to use the repositoy exposed via Caddy

It's enough to add record a new repository configuration, and only setting the
URL, relying on the default values for the other settings.

```shell
cat /usr/local/etc/pkg/repos/custom.conf
custom: {
  url: "http://ptidoux.local/packages/14-2-amd64-main",
}

# Force updating repositories
daos pkg update -f
```
