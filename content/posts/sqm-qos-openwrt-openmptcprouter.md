---
title: "SQM QoS OpenWrt OpenMPTCProuter"
date: 2020-05-20T12:50:27+02:00
tags:
  - openmptcprouter
  - adsl
  - qos
---

# Doing QoS with OpenMPTCProuter

I'm at the countryside so no fiber/FTTH but only FTTD (Fiber To The DSLAM)...
Being a remote worker I need a quite stable connection, so I'm currently using
3 ADSL connections aggregated via OpenMPTCProuter. Thus not only if one link
fail it will be transparent but the upload and download links are aggregated,
it's not only a failover on the links.
Initially I was an [OverTheBox]() user, but that's [another story](https://community.ovh.com/t/inutilisable-depuis-plusieurs-jours-bye-bye-overthebox-welcome-openmptcprouter/11844)...

[OpenMPTCProuter](https://www.openmptcprouter.com/) is based on
[OpenWrt](https://openwrt.org) and includes Smart Queue Management (SQM)
allowing to do traffic shaping.
Due to this it's possible to use the standard [SQM
documentation](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm),
basically it involves:

- measuring the current speed of the setup
- computing the download and upload caps
- configuring SQM appropriately

## Measuring the current speed of the setup

Various convenient online services are available to test your connection.
I'm using https://nperf.com with a free registered account as they provide an
history of the checks, so it's quite convenient.

Be sure to do multiple test to have a propre idea of the speed.

With my 3 ADSL connections I measured:

- average download around 33/34 megabits/s
- average upload around 1.5/1.7 megabits/s
- average ping around 27/33 ms

My ADSL connections are around 10-12 Mb each, so it's coherent.

### Measuring speed from the CLI

In order to measure the download time you could also just download some files
from the CLI and see the speed, OVH provides some [convenient
files](http://proof.ovh.net/files/) for this.

```sh
wget -O /dev/null http://proof.ovh.net/files/10Mb.dat
```

For the upload it's not as easy as you will need service listening on the
internet, `nc` can be used for this.

```sh
# On the remote server, be sure to have port 4444 open
 nc -v -l 4242 > /dev/null
# From a local computer
dd if=/dev/zero bs=1024K count=512 | nc -v $SERVER_IP 4242
# Then you will be able to check dd's output
```

## Computing the download and upload caps

For the download and upload caps [SQM
Documentation](https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm)
recommends using a max value between 80 and 95 % of the measured value.

To be a bit conservative I selected 85%:

- 33000 \* 0.85 = 28050
- 1.600 \* 0.85 = 1360

## Configuring SQM in OpenMPTCProuter

Assuming OpenMPTCProuter will be reachable at 192.168.100.1, the configuration
should be done at S http://192.168.100.1/cgi-bin/luci/admin/network/sqm (so
under Network->SQM QoS).

As I want to do QoS on the aggregated MPTCP link it's on the tun0 (omrvpn)
interface, be sure to configure SQM for this specific interface.

In the `Basic Settings` tab:

- Ensure that this SQM instance is enabled
- Download speed: 28050
- Upload speed: 1360

In the `Queue Discipline` tab:

- Queuing disciplines usable: cake
- Queue setup script: piece_of_cake.qos

In the `Link Layer Adapation` tab:

- Which link layer to account for: ATM (as I'm using 3 ADSL connections)
- Per packet Overhead: 44

Then save an apply!
