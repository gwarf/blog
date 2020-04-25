---
title: "Monitoring with Sensu"
date: 2020-04-25T15:56:13+02:00
toc: false
draft: false
images:
tags:
  - sysadmin
  - monitoring
  - sensu
---

Some notes taken during a deployment of Sensu with one backend server and some
nodes running agents.

## Installing Sensu

Follow the [official documentation](https://docs.sensu.io/sensu-go/latest/installation/install-sensu/).

### Installing the backend

```sh
# Add the Sensu repository
curl -s https://packagecloud.io/install/repositories/sensu/stable/script.rpm.sh | sudo bash
# Install the sensu-go-backend package
sudo yum install sensu-go-backend
# Copy the config template from the docs
sudo curl -L https://docs.sensu.io/sensu-go/latest/files/backend.yml -o /etc/sensu/backend.yml
# Start sensu-backend
sudo systemctl enable --now sensu-backend
# Initialise
sudo systemctl status -l sensu-backend
export SENSU_BACKEND_CLUSTER_ADMIN_USERNAME=YOUR_USERNAME
export SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD=YOUR_PASSWORD
sensu-backend init
# Check that backend replies
curl http://127.0.0.1:8080/health
```

### Installing the client

The client is used to interact with the backend from CLI using `sensuctl`.

```sh
# Add the Sensu repository
curl https://packagecloud.io/install/repositories/sensu/stable/script.rpm.sh | sudo bash
# Install the sensu-go-cli package
sudo yum install sensu-go-cli
sensuctl configure -n \
--username $SENSU_BACKEND_CLUSTER_ADMIN_USERNAME \
--password $SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD \
--namespace default \
--url 'http://127.0.0.1:8080'
sensuctl config view
```

### Configure CA and certificates

Follow the [official documentation](https://docs.sensu.io/sensu-go/latest/guides/generate-certificates/).

```sh
# Download cfssl and cfssljson executables and install them in /usr/local/bin:
sudo curl -L https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl_1.4.1_linux_amd64 -o /usr/local/bin/cfssl
sudo curl -L https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssljson_1.4.1_linux_amd64 -o /usr/local/bin/cfssljson
sudo chmod +x /usr/local/bin/cfssl*
# Create /etc/sensu/tls -- does not exist by default
sudo su -
mkdir -p /etc/sensu/tls
cd /etc/sensu/tls
# Create the Certificate Authority
echo '{"CN":"Sensu Test CA","key":{"algo":"rsa","size":2048}}' | cfssl gencert -initca - | cfssljson -bare ca -
# Define signing parameters and profiles. Note that agent profile provides the "client auth" usage required for mTLS.
echo '{"signing":{"default":{"expiry":"17520h","usages":["signing","key encipherment","client auth"]},"profiles":{"backend":{"usages":["signing","key encipherment","server auth"],"expiry":"4320h"},"agent":{"usages":["signing","key encipherment","client auth"],"expiry":"4320h"}}}}' > ca-config.json
# Issue backend certificate
export ADDRESS=localhost,127.0.0.1,$BACKEND_IP,$BACKEND_FQDN
export NAME=$BACKEND_FQDN
echo '{"CN":"'$NAME'","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -config=ca-config.json -profile="backend" -ca=ca.pem -ca-key=ca-key.pem -hostname="$ADDRESS" - | cfssljson -bare $NAME
# Issue agents' certificates
export NAME=$AGENT_NAME
echo '{"CN":"'$NAME'","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -hostname="" -profile=agent - | cfssljson -bare $NAME
chown sensu /etc/sensu/tls/*.pem
chmod 400 /etc/sensu/tls/*.pem
chown root /etc/sensu/tls/ca.pem
chmod 644 /etc/sensu/tls/ca.pem
```

- Copy agent's certificate and key to `/etc/sensu/tls` on each agent nodes.

```sh
# Configuration for mail node
tree /etc/sensu
/etc/sensu
├── agent.yml
└── tls
    ├── ca.pem
    ├── mail-key.pem
    └── mail.pem

1 directory, 4 files
```

```sh
# Add Sensu CA to system trust store
# CentOS
chmod 644 /etc/sensu/tls/ca.pem
chown root /etc/sensu/tls/ca.pem
sudo yum install -y ca-certificates
sudo update-ca-trust force-enable
sudo ln -s /etc/sensu/tls/ca.pem /etc/pki/ca-trust/source/anchors/sensu-ca.pem
sudo update-ca-trust
# Ubuntu
chmod 644 /etc/sensu/tls/ca.pem
chown root /etc/sensu/tls/ca.pem
sudo apt-get install ca-certificates -y
sudo ln -sfv /etc/sensu/tls/ca.pem /usr/local/share/ca-certificates/sensu-ca.crt
sudo update-ca-certificates
# Arch
sudo trust anchor --store /etc/sensu/tls/ca.pem
```

```sh
➜  ~ sudo grep -v '^\(#.*\|\s*\)$' /etc/sensu/backend.yml
---
state-dir: "/var/lib/sensu/sensu-backend"
log-level: "debug" # available log levels: panic, fatal, error, warn, info, debug
api-url: "https://localhost:8080"
dashboard-cert-file: "/etc/sensu/tls/$BACKEND_FQDN.pem"
dashboard-key-file: "/etc/sensu/tls/$BACKEND_FQDN-key.pem"
dashboard-host: "[::]" # listen on all IPv4 and IPv6 addresses
dashboard-port: 3000
cert-file: "/etc/sensu/tls/$BACKEND_FQDN.pem"
key-file: "/etc/sensu/tls/$BACKEND_FQDN-key.pem"
trusted-ca-file: "/etc/sensu/tls/ca.pem"
insecure-skip-tls-verify: false
etcd-advertise-client-urls: "https://localhost:2379"
etcd-listen-client-urls: "https://localhost:2379"
etcd-listen-peer-urls: "https://localhost:2380"
etcd-initial-advertise-peer-urls: "https://localhost:2380"
etcd-cert-file: "/etc/sensu/tls/$BACKEND_FQDN.pem"
etcd-key-file: "/etc/sensu/tls/$BACKEND_FQDN-key.pem"
etcd-trusted-ca-file: "/etc/sensu/tls/ca.pem"
etcd-peer-cert-file: "/etc/sensu/tls/$BACKEND_FQDN.pem"
etcd-peer-key-file: "/etc/sensu/tls/$BACKEND_FQDN-key.pem"
etcd-peer-client-cert-auth: "true"
etcd-peer-trusted-ca-file: "/etc/sensu/tls/ca.pem"
```

```sh
# Restart backend
sudo systemctl restart sensu-backend
# Update sensuctl to use https
sensuctl configure -n \
--username $SENSU_BACKEND_CLUSTER_ADMIN_USERNAME \
--password $SENSU_BACKEND_CLUSTER_ADMIN_PASSWORD \
--namespace default \
--url 'http://127.0.0.1:8080'
```

### Allowing client and agents to connect to the backend

`$CLIENT_IP` is the IP of the host accessing the Web interface.

```sh
# Allowing to access the sensu dashboard running on port 3000
sudo ufw allow from $CLIENT_IP to any port 3000
# Allowing an agent to connect to the Sensu backend
sudo ufw allow from $AGENT_IP to any port 8081
```

The sensu web interface is available on `https://$BACKEND_FQDN:3000`.

### Installing and configuring agents

```sh
# Add the Sensu repository
curl -s https://packagecloud.io/install/repositories/sensu/stable/script.rpm.sh | sudo bash
# Install the sensu-go-agent package
sudo yum install sensu-go-agent
# Copy the config template from the docs
sudo curl -L https://docs.sensu.io/sensu-go/latest/files/agent.yml -o /etc/sensu/agent.yml
# Start sensu-agent using a service manager
sudo systemctl enable --now sensu-agent
sudo systemctl status -l sensu-agent
```

#### Edit configuration

```sh
grep -v '^\(#.*\|\s*\)$' /etc/sensu/agent.yml
---
backend-url:
  - "wss://$BACKEND_IP:8081"
log-level: "debug"
trusted-ca-file: "/etc/sensu/tls/ca.pem"
subscriptions:
  - system
  # On the host testing the remote mail server
  - mailcow
```

#### Check agents listed in the backend

```sh
# Checking agent's heartbeats
sensuctl entity list
```

## Monitoring with Sensu

```sh
# Installing plugins
sensuctl asset add sensu-plugins/sensu-plugins-cpu-checks -r cpu-checks-plugins
sensuctl asset add sensu/sensu-ruby-runtime -r sensu-ruby-runtime
sensuctl asset add sensu/sensu-email-handler -r email-handler
sensuctl asset add sensu/monitoring-plugins
sensuctl asset add dhpowrhost/sensu-plugins-imap
# Add a mail handler
cat << EOF | sensuctl create
---
api_version: core/v2
type: Handler
metadata:
  namespace: default
  name: email
spec:
  type: pipe
  command: sensu-email-handler -f $MAIL_FROM -t $MAIL_TO -s $MAIL_SERVER -u $MAIL_USER -p $MAIL_PASS
  timeout: 10
  filters:
  - is_incident
  - not_silenced
  - state_change_only
  runtime_assets:
  - email-handler
EOF
# Creating checks
sensuctl check create check-cpu \
  --command 'check-cpu.rb -w 75 -c 90' \
  --interval 60 \
  --subscriptionssystem \
  --runtime-assets cpu-checks-plugins,sensu-ruby-runtime \
  --handlers email
sensuctl check create check-disk-usage \
  --command "check-disk-usage.rb -w 70 -c 90 x debugfs,tracefs,proc,overlay,nsfs -p '(\/var\/lib\/docker|\/snap)'" \
  --interval 60 \
  --subscriptions system \
  --runtime-assets sensu-plugins/sensu-plugins-disk-checks \
  --handlers email
sensuctl check create check-smtp \
  --command 'check_smtp -H $MAIL_SERVER -p 587 -U $MAIL_USER -P $MAIL_PASS' \
  --interval 60 \
  --subscriptions mailcow \
  --runtime-assets sensu/monitoring-plugins \
  --handlers email
sensuctl check create check-imap \
  --command 'check-imap.rb -h $MAIL_SERVER -p 993 -u $MAIL_USER -p $MAIL_PASS' \
  --interval 60 \
  --subscriptions mailcow \
  --runtime-assets dhpowrhost/sensu-plugins-imap,sensu-ruby-runtime \
  --handlers email
```
