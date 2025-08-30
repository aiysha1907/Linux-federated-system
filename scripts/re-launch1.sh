#!/bin/bash
NODE="node1"
TAP="tap1"
DISK="$HOME/ebpf-lab/qemu-nodes/$NODE.qcow2"
SOCK="$HOME/ebpf-lab/qemu-nodes/serial-$NODE.sock"
BRIDGE="br0"

echo "[+] Cleaning up $TAP..."
sudo ip link delete $TAP 2>/dev/null || true

echo "[+] Creating TAP interface..."
sudo ip tuntap add dev $TAP mode tap
sudo ip link set $TAP master $BRIDGE
sudo ip link set $TAP up

echo "[+] Launching $NODE..."
sudo qemu-system-x86_64 -cdrom ~/ebpf-lab/base-images/ubuntu-22.04.5-live-server-amd64.iso  \
  -name $NODE \
  -m 1024 \
  -smp 1 \
  -drive file="$DISK",if=virtio \
  -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
  -device e1000,netdev=net0,mac=52:54:00:12:34:61 \
  -serial unix:"$SOCK",server,nowait \
  -usb -device usb-tablet \
  -display default \
  -daemonize
