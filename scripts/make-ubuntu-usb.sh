#!/usr/bin/env bash
# Writes Ubuntu desktop ISO to a USB stick (whole-disk, bootable).
# Usage: make-ubuntu-usb.sh <disk_number> [iso_path]
# Example: make-ubuntu-usb.sh 4
#          make-ubuntu-usb.sh 4 /tmp/ubuntu-24.04.4-desktop-amd64.iso
# Plug in the USB, run 'diskutil list' to find the disk (e.g. disk4 = use 4).
# Use -y to skip the confirmation prompt.

set -e
SKIP_CONFIRM=
[[ "${1:-}" == "-y" ]] && { SKIP_CONFIRM=1; shift; }
DISK_NUM="${1:?Usage: $0 [-y] <disk_number> [iso_path]}"
ISO="${2:-/tmp/ubuntu-24.04.4-desktop-amd64.iso}"

if [[ ! -f "$ISO" ]]; then
  echo "ISO not found: $ISO"
  echo "Download from: https://releases.ubuntu.com/24.04/ubuntu-24.04.4-desktop-amd64.iso"
  exit 1
fi

DISK="disk${DISK_NUM}"
RDISK="rdisk${DISK_NUM}"

if ! diskutil info "$DISK" &>/dev/null; then
  echo "Disk $DISK not found. Run 'diskutil list' and use the number of your USB (e.g. 4 for disk4)."
  exit 1
fi

echo "Target: $DISK ($RDISK)"
echo "ISO:    $ISO"
if [[ -z "$SKIP_CONFIRM" ]]; then
  echo "This will ERASE all data on $DISK. Press Enter to continue, Ctrl+C to abort."
  read -r
fi

diskutil unmountDisk "$DISK"
# macOS dd uses bs in bytes; 4m is invalid, use 4MiB. status=progress is GNU-only.
sudo dd if="$ISO" of="/dev/$RDISK" bs=4194304
diskutil eject "$DISK"
echo "Done. USB is now a bootable Ubuntu installer."
