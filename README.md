# Federated eBPF-Based Multi-Node System

## Project Overview
This project sets up a multi-node environment using QEMU virtual machines, bridged networking with TAP interfaces, and DHCP via dnsmasq.  
Each node runs Ubuntu and captures TLS metadata using eBPF probes. The metadata is forwarded to a Kafka broker for further analysis.  

---

## Prerequisites
- Ubuntu (host machine)
- QEMU installed
- `dnsmasq` installed
- `bridge-utils` installed
- `cloud-init` for VM initialization

---

## Networking Setup


```bash
### 1. Create and configure a Linux bridge
sudo ip link add br0 type bridge
sudo ip addr add 192.168.100.1/24 dev br0
sudo ip link set br0 up

### 2. Configure dnsmasq for DHCP
interface=br0
bind-interfaces
dhcp-range=192.168.100.50,192.168.100.100,12h

sudo systemctl restart dnsmasq


