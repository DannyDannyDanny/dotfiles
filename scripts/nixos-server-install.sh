#!/bin/bash
# Install NixOS with disko (LUKS + root) on a live system.
# Prompts for hostname and target disk, then provisions the installed system
# (clones dotfiles, installs SSH key, generates hardware config).
#
# Usage (from repo root, e.g. /tmp/dotfiles):
#   sudo ./scripts/nixos-server-install.sh
#
# Environment variables (all optional):
#   INSTALLER_HOSTNAME   — skip hostname prompt
#   INSTALLER_DISK       — skip disk prompt (validated as block device)
#   SSH_PUBKEY_FILE      — path to .pub file; installed to danny's authorized_keys
#   FLAKE_REF            — override flake reference (default: auto-detect from repo)
#   INSTALLER_SYSTEM_CONFIG_FILE — JSON file merged into --system-config
set -euo pipefail

FLAKE_REF="${FLAKE_REF:-}"
if [[ -z "$FLAKE_REF" ]]; then
  if [[ -d "$(dirname "$0")/../nixos" ]] && [[ -f "$(dirname "$0")/../nixos/flake.nix" ]]; then
    REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    FLAKE_REF="path:${REPO_ROOT}/nixos"
  else
    echo "FLAKE_REF not set and not running from dotfiles repo. Example:"
    echo "  export FLAKE_REF=github:USER/REPO   # or path:/path/to/dotfiles/nixos"
    exit 1
  fi
fi

if [[ "$EUID" -ne 0 ]]; then
  echo "Run as root (e.g. sudo $0)"
  exit 1
fi

# --- Hostname ---
hostname="${INSTALLER_HOSTNAME:-}"
if [[ -z "$hostname" ]]; then
  read -r -p "Hostname (e.g. phantom-ship): " hostname
fi
if [[ -z "$hostname" ]]; then
  echo "Hostname cannot be empty."
  exit 1
fi

# --- Target disk ---
disk="${INSTALLER_DISK:-}"
if [[ -z "$disk" ]]; then
  read -r -p "Target disk [default: /dev/sda]: " disk
  disk="${disk:-/dev/sda}"
fi
if [[ ! -b "$disk" ]]; then
  echo "Not a block device: $disk"
  exit 1
fi

# --- System config (hostname + optional extras) ---
if [[ -n "${INSTALLER_SYSTEM_CONFIG_FILE:-}" ]] && [[ -f "$INSTALLER_SYSTEM_CONFIG_FILE" ]]; then
  if command -v jq &>/dev/null; then
    SYSTEM_CONFIG=$(jq --arg h "$hostname" '.networking.hostName = $h' "$INSTALLER_SYSTEM_CONFIG_FILE")
  else
    SYSTEM_CONFIG=$(cat "$INSTALLER_SYSTEM_CONFIG_FILE")
    echo "Warning: jq not found, using file as-is (hostname may not match)."
  fi
else
  SYSTEM_CONFIG='{"networking":{"hostName":"'"$hostname"'"}}'
fi

# --- Optional: danny password ---
danny_pass=""
read -r -p "Set a password for user danny? [y/N] " set_pass
if [[ "${set_pass,,}" == "y" || "${set_pass,,}" == "yes" ]]; then
  read -s -r -p "Password for danny: " danny_pass
  echo
  read -s -r -p "Confirm password: " danny_pass2
  echo
  if [[ "$danny_pass" != "$danny_pass2" ]]; then
    echo "Passwords do not match. Aborted."
    exit 1
  fi
  if [[ -z "$danny_pass" ]]; then
    echo "Password cannot be empty. Aborted."
    exit 1
  fi
  HASH=$(echo -n "$danny_pass" | openssl passwd -6 -stdin 2>/dev/null) || HASH=$(mkpasswd -6 -m sha-512 "$danny_pass" 2>/dev/null) || true
  if [[ -n "${HASH:-}" ]]; then
    if command -v jq &>/dev/null; then
      SYSTEM_CONFIG=$(echo "$SYSTEM_CONFIG" | jq --arg h "$HASH" '. + {"users":{"users":{"danny":{"hashedPassword":$h}}}}')
    else
      NEW_CONFIG=$(echo "$SYSTEM_CONFIG" | nix run nixpkgs#jq -- --arg h "$HASH" '. + {"users":{"users":{"danny":{"hashedPassword":$h}}}}' 2>/dev/null)
      [[ -n "$NEW_CONFIG" ]] && SYSTEM_CONFIG="$NEW_CONFIG" || echo "Could not merge password. Set after boot: passwd danny"
    fi
    echo "Password will be set for danny."
  else
    echo "Could not hash password (need openssl or mkpasswd). Set after boot: passwd danny"
  fi
fi

# --- Confirm and install ---
echo ""
echo "=== Install Summary ==="
echo "Flake:      ${FLAKE_REF}#server-install"
echo "Disk:       $disk"
echo "Hostname:   $hostname"
echo "SSH pubkey: ${SSH_PUBKEY_FILE:-none}"
echo "System config: $SYSTEM_CONFIG"
read -r -p "Proceed? [y/N] " confirm
if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

nix run --extra-experimental-features "nix-command flakes" \
  github:nix-community/disko/latest#disko-install -- \
  --flake "${FLAKE_REF}#server-install" \
  --disk main "$disk" \
  --system-config "$SYSTEM_CONFIG"

echo ""
echo "=== Post-install provisioning ==="
echo "Re-opening LUKS to provision the installed system..."
read -s -r -p "LUKS passphrase: " luks_pass
echo

LUKS_DEV="/dev/disk/by-partlabel/disk-main-luks"
ESP_DEV="/dev/disk/by-partlabel/disk-main-ESP"
if [[ ! -b "$LUKS_DEV" ]]; then
  LUKS_DEV="${disk}2"
  ESP_DEV="${disk}1"
fi

if [[ ! -b "$LUKS_DEV" ]]; then
  echo "Could not find LUKS partition. Complete these steps manually after boot:"
  echo "  1. Clone dotfiles: sudo git clone ... /etc/dotfiles"
  echo "  2. Add SSH key: mkdir -p ~/.ssh && cat /tmp/key.pub >> ~/.ssh/authorized_keys"
  echo "  3. Generate hardware config: nixos-generate-config --show-hardware-config > /etc/dotfiles/nixos/hosts/${hostname}-hardware.nix"
  exit 0
fi

if [[ -e /dev/mapper/crypted ]]; then
  echo "  [ok] LUKS device already open (left open by disko-install)"
  unset luks_pass
elif ! echo -n "$luks_pass" | cryptsetup open "$LUKS_DEV" crypted --key-file -; then
  echo "Wrong LUKS passphrase. Complete provisioning manually after boot."
  unset luks_pass
  exit 0
else
  unset luks_pass
fi

mount /dev/mapper/crypted /mnt
[[ -b "$ESP_DEV" ]] && mount "$ESP_DEV" /mnt/boot
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# 1. Set danny password (belt-and-suspenders; Nix merge can fail)
if [[ -n "$danny_pass" ]]; then
  echo "danny:${danny_pass}" | chroot /mnt chpasswd
  echo "  [ok] danny password set"
fi
unset danny_pass

# 2. Clone dotfiles
if [[ ! -d /mnt/etc/dotfiles ]]; then
  chroot /mnt nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- \
    clone https://github.com/DannyDannyDanny/dotfiles.git /etc/dotfiles
  echo "  [ok] dotfiles cloned to /etc/dotfiles"
else
  echo "  [skip] /etc/dotfiles already exists"
fi

# 3. Install SSH public key
if [[ -n "${SSH_PUBKEY_FILE:-}" ]] && [[ -f "$SSH_PUBKEY_FILE" ]]; then
  mkdir -p /mnt/home/danny/.ssh
  cat "$SSH_PUBKEY_FILE" >> /mnt/home/danny/.ssh/authorized_keys
  chmod 700 /mnt/home/danny/.ssh
  chmod 600 /mnt/home/danny/.ssh/authorized_keys
  chroot /mnt chown -R danny:users /home/danny/.ssh
  echo "  [ok] SSH public key installed"
elif [[ -n "${SSH_PUBKEY_FILE:-}" ]]; then
  echo "  [warn] SSH_PUBKEY_FILE set but file not found: $SSH_PUBKEY_FILE"
fi

# 4. Generate hardware config
HW_CONFIG="/mnt/etc/dotfiles/nixos/hosts/${hostname}-hardware.nix"
if nixos-generate-config --show-hardware-config --root /mnt > "$HW_CONFIG" 2>/dev/null; then
  echo "  [ok] hardware config saved to hosts/${hostname}-hardware.nix"
  echo "  NOTE: Commit this file to the repo after first boot."
else
  echo "  [warn] nixos-generate-config failed; run manually after boot:"
  echo "    nixos-generate-config --show-hardware-config > /etc/dotfiles/nixos/hosts/${hostname}-hardware.nix"
fi

umount -R /mnt
cryptsetup close crypted

echo ""
echo "=== Done! ==="
echo "Remove the USB and reboot. After unlocking LUKS:"
echo "  1. SSH in: ssh danny@${hostname}"
echo "  2. First rebuild: cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#${hostname}"
echo "  3. Commit ${hostname}-hardware.nix back to the repo"
