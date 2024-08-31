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
is for [caddy](https://caddyserver.com/) and allows to have a very simple setup.

### Installing Caddy

Caddy is availalbe as a port.

```shell
doas pkg install caddy
```

### Configuring Caddy

Caddyi will only serve a single host, this I will replace the existing
configuation.

There is also a sample configuration at `/usr/local/etc/caddy/Caddyfile.sample`.
```shell
doas cp /usr/local/share/examples/poudriere/Caddyfile.sample /usr/local/etc/caddy/Caddyfile
```

Edit `/usr/local/etc/caddy/Caddyfile`, to adjust the path to poudriere, if
needed. In my previous post I used `/poudriere` as `BASEFS`, thus I should
replace `/usr/local/poudriere/data/` as `/poudriere/data/`.
I will also set the host name to localhost.

The resulting file, with strippred comment is:

```text
localhost {
	root * /usr/local/share/poudriere/html
	file_server
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
}
```

Start Caddy manually as it's not expected to be used all the time:

```shell
# Start caddy manually
doas service caddy onestart
```

Then open [https://localhost](https://localhost), and accept the certificate.
