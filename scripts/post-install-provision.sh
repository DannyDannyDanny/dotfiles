#!/bin/bash
# Run after disko-install when LUKS is already open.
# Usage: curl -fsSL https://raw.githubusercontent.com/DannyDannyDanny/dotfiles/main/scripts/post-install-provision.sh | sudo bash -s -- phantom-ship
set -euo pipefail

HOSTNAME="${1:-phantom-ship}"
USB_DATA="/tmp/usb-data"
REPO="https://github.com/DannyDannyDanny/dotfiles.git"

echo "=== Post-install provisioning for ${HOSTNAME} ==="

# Mount installed system (LUKS already open from disko-install)
mount /dev/mapper/crypted /mnt
mount /dev/disk/by-partlabel/disk-main-ESP /mnt/boot 2>/dev/null || true
for d in dev proc sys; do mount --bind /$d /mnt/$d; done

# Clone dotfiles — find git or nix, clone directly into /mnt (no chroot)
if [[ ! -d /mnt/etc/dotfiles ]]; then
  # Ensure nix is in PATH (live installer may strip it under sudo)
  export PATH=$PATH:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin
  if command -v git &>/dev/null; then
    git clone "$REPO" /mnt/etc/dotfiles
  else
    nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- \
      clone "$REPO" /mnt/etc/dotfiles
  fi
  echo "[ok] dotfiles cloned"
else
  echo "[skip] dotfiles already present"
fi

# Install SSH key
if [[ -f "$USB_DATA/authorized_keys" ]]; then
  mkdir -p /mnt/home/danny/.ssh
  cp "$USB_DATA/authorized_keys" /mnt/home/danny/.ssh/authorized_keys
  chmod 700 /mnt/home/danny/.ssh
  chmod 600 /mnt/home/danny/.ssh/authorized_keys
  chroot /mnt chown -R danny:users /home/danny/.ssh
  echo "[ok] SSH key installed"
else
  echo "[warn] no authorized_keys on USB — add SSH key manually after boot"
fi

# Generate hardware config
nixos-generate-config --show-hardware-config --root /mnt \
  > /mnt/etc/dotfiles/nixos/hosts/${HOSTNAME}-hardware.nix
echo "[ok] hardware config saved to hosts/${HOSTNAME}-hardware.nix"

# Copy hardware config to USB for committing from Mac
mkdir -p "$USB_DATA"
cp /mnt/etc/dotfiles/nixos/hosts/${HOSTNAME}-hardware.nix "$USB_DATA/"
echo "[ok] hardware config also copied to USB ($USB_DATA/)"

umount -R /mnt
cryptsetup close crypted 2>/dev/null || true

echo ""
echo "=== Done! Remove USB and reboot. ==="
echo "After unlocking LUKS, SSH in: ssh danny@${HOSTNAME}"
echo "Then: cd /etc/dotfiles && sudo nixos-rebuild switch --flake .#${HOSTNAME}"
echo "Commit ${HOSTNAME}-hardware.nix from the USB back to the repo."
