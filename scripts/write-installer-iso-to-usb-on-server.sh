#!/usr/bin/env bash
# Run this script ON the server (sunken-ship) with the USB stick plugged in.
# It finds the USB device, unmounts it, and writes the installer ISO to it.
# Usage: sudo ./scripts/write-installer-iso-to-usb-on-server.sh [path_to_iso]
#   path_to_iso: default is ~/dotfiles-iso-build/nixos/result/iso/*.iso from the build
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Run as root: sudo $0 [$*]"
  exit 1
fi

ISO="${1:-}"
if [[ -z "$ISO" ]]; then
  for base in /home/danny ~; do
    ISO=$(ls "$base/dotfiles-iso-build/nixos/result/iso/"*.iso 2>/dev/null | head -1)
    [[ -n "$ISO" ]] && break
  done
fi
if [[ -z "$ISO" || ! -f "$ISO" ]]; then
  echo "ISO not found. Pass path: sudo $0 /path/to/nixos-minimal-*.iso"
  exit 1
fi

echo "Block devices:"
lsblk -d -o NAME,SIZE,MODEL,TRAN
echo ""
echo "Identify the USB (usually the smaller removable disk, e.g. sdb or nvme1n1)."
read -r -p "Device to overwrite (e.g. sdb, no /dev/): " dev
dev="/dev/${dev#/dev/}"
if [[ ! -b "$dev" ]]; then
  echo "Not a block device: $dev"
  exit 1
fi

# Unmount any partitions on the device
for part in "${dev}"*; do
  [[ "$part" == "$dev" ]] && continue
  if mountpoint -q "$part" 2>/dev/null || mount | grep -q "$part"; then
    umount "$part" 2>/dev/null || true
  fi
done

echo "About to write $ISO to $dev (all data on $dev will be destroyed)."
read -r -p "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 0
fi

echo "Writing..."
dd if="$ISO" of="$dev" bs=4M status=progress
sync
echo "Done. Safe to remove the USB."
