#!/bin/bash
set -e

NODE_DIR="$HOME/ebpf-lab/qemu-nodes"
RAM_MB=1024
BRIDGE="br0"

for i in 1 2 3; do
  echo "[+] Relaunching node$i..."

  QCOW2="$NODE_DIR/node$i.qcow2"
  TAP_IF="tap$i"
  SOCK="$NODE_DIR/serial-node$i.sock"

  # Cleanup
  sudo ip link delete $TAP_IF 2>/dev/null || true
  rm -f "$SOCK"

  # Create TAP interface
  sudo ip tuntap add dev $TAP_IF mode tap
  sudo ip link set $TAP_IF master $BRIDGE
  sudo ip link set $TAP_IF up

  # Relaunch from DISK (not ISO)
  sudo qemu-system-x86_64 \
    -m $RAM_MB \
    -smp 1 \
    -boot c \
    -drive file="$QCOW2",if=virtio \
    -netdev tap,id=net$i,ifname=$TAP_IF,script=no,downscript=no \
    -device e1000,netdev=net$i \
    -usbdevice tablet \
    -serial unix:"$SOCK",server,nowait \
    -display default \
    -name "node$i" \
    -daemonize
done

echo "[✓] VMs launched from disk. Use serial console to login:"
echo "  socat - UNIX-CONNECT:$NODE_DIR/serial-node1.sock"
