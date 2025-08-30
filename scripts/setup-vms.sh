#!/bin/bash
set -e

echo "===== Launching Clean QEMU Ubuntu VMs with ISO Installer ====="

BASE_ISO="$HOME/ebpf-lab/base-images/ubuntu-22.04.5-live-server-amd64.iso"
NODE_DIR="$HOME/ebpf-lab/qemu-nodes"
BRIDGE="br0"
RAM_MB=1024
DISK_SIZE=6G
NODE_COUNT=3

mkdir -p "$NODE_DIR"

# Create bridge if not already up
if ! ip link show "$BRIDGE" &>/dev/null; then
  echo "[+] Creating bridge $BRIDGE"
  sudo ip link add name "$BRIDGE" type bridge
  sudo ip addr add 192.168.100.1/24 dev "$BRIDGE" || true
  sudo ip link set "$BRIDGE" up
else
  echo "[✓] Bridge $BRIDGE already exists"
fi

# Loop over nodes
for i in $(seq 1 $NODE_COUNT); do
  echo -e "\n[+] Creating node$i..."

  QCOW2="$NODE_DIR/node$i.qcow2"
  TAP_IF="tap$i"
  SOCK="$NODE_DIR/serial-node$i.sock"

  # Cleanup if exists
  sudo ip link delete "$TAP_IF" 2>/dev/null || true
  rm -f "$QCOW2" "$SOCK"

  # Create TAP interface and attach to bridge
  sudo ip tuntap add dev "$TAP_IF" mode tap
  sudo ip link set "$TAP_IF" master "$BRIDGE"
  sudo ip link set "$TAP_IF" up

  # Create disk image
  qemu-img create -f qcow2 "$QCOW2" "$DISK_SIZE"

  # Launch QEMU VM with ISO installer
  sudo qemu-system-x86_64 \
    -m "$RAM_MB" \
    -smp 1 \
    -boot d \
    -drive file="$QCOW2",if=virtio \
    -cdrom "$BASE_ISO" \
    -netdev tap,id=net$i,ifname=$TAP_IF,script=no,downscript=no \
    -device e1000,netdev=net$i \
    -usbdevice tablet \
    -serial unix:"$SOCK",server,nowait \
    -display default \
    -name "node$i" \
    -daemonize
done

echo -e "\n===== All VMs Launched with ISO Installer. Proceed with Manual OS Install Inside Each ====="
