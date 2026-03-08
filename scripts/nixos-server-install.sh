#!/bin/bash
# Run on a NixOS minimal live system (or installer ISO) to install NixOS with
# disko (LUKS + root). Prompts for hostname and target disk; optionally use
# INSTALLER_SYSTEM_CONFIG_FILE for WiFi etc.
#
# Usage (from repo root, e.g. /tmp/dotfiles):
#   sudo ./scripts/nixos-server-install.sh
# If you see "command not found", use: sudo bash ./scripts/nixos-server-install.sh
#
# Optional: FLAKE_REF=github:User/dotfiles or path:/path/to/dotfiles/nixos
#
# Optional: INSTALLER_SYSTEM_CONFIG_FILE=/path/to/json with full --system-config
# (e.g. hostName + networking.wireless.networks). If unset, only hostname is passed.
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

read -r -p "Hostname (e.g. my-server): " hostname
if [[ -z "$hostname" ]]; then
  echo "Hostname cannot be empty."
  exit 1
fi

read -r -p "Target disk [default: /dev/sda]: " disk
disk="${disk:-/dev/sda}"
if [[ ! -b "$disk" ]]; then
  echo "Not a block device: $disk"
  exit 1
fi

if [[ -n "${INSTALLER_SYSTEM_CONFIG_FILE:-}" ]] && [[ -f "$INSTALLER_SYSTEM_CONFIG_FILE" ]]; then
  # Use provided JSON; ensure hostname is set
  if command -v jq &>/dev/null; then
    SYSTEM_CONFIG=$(jq --arg h "$hostname" '.networking.hostName = $h' "$INSTALLER_SYSTEM_CONFIG_FILE")
  else
    SYSTEM_CONFIG=$(cat "$INSTALLER_SYSTEM_CONFIG_FILE")
    echo "Warning: jq not found, using file as-is (hostname may not match)."
  fi
else
  SYSTEM_CONFIG='{"networking":{"hostName":"'"$hostname"'"}}'
fi

# Prompt for password for danny so you can log in at console after reboot (no rescue needed)
read -r -p "Set a password for user danny (console/SSH login)? [y/N] " set_pass
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
  HASH=$(echo -n "$danny_pass" | openssl passwd -6 -stdin 2>/dev/null) || HASH=$(mkpasswd -6 -m sha-512 "$danny_pass" 2>/dev/null)
  if [[ -z "$HASH" ]]; then
    echo "Could not hash password (need openssl or mkpasswd). Skipping password."
  else
    if command -v jq &>/dev/null; then
      SYSTEM_CONFIG=$(echo "$SYSTEM_CONFIG" | jq --arg h "$HASH" '. + {"users":{"users":{"danny":{"hashedPassword":$h}}}}')
    else
      NEW_CONFIG=$(echo "$SYSTEM_CONFIG" | nix run nixpkgs#jq -- --arg h "$HASH" '. + {"users":{"users":{"danny":{"hashedPassword":$h}}}}' 2>/dev/null)
      [[ -n "$NEW_CONFIG" ]] && SYSTEM_CONFIG="$NEW_CONFIG" || echo "Could not merge password (jq not found). Set after boot: passwd danny"
    fi
    [[ -n "$SYSTEM_CONFIG" ]] && echo "Password will be set for danny."
  fi
fi

echo "Flake:      ${FLAKE_REF}#server-install"
echo "Disk:       $disk"
echo "Hostname:   $hostname"
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

# Set danny password directly on disk (Nix merge can fail); re-open LUKS and chroot
if [[ -n "${danny_pass:-}" ]]; then
  echo "Setting password for danny on installed system (re-enter LUKS passphrase once)..."
  read -s -r -p "LUKS passphrase: " luks_pass
  echo
  LUKS_DEV="/dev/disk/by-partlabel/disk-main-luks"
  ESP_DEV="/dev/disk/by-partlabel/disk-main-ESP"
  if [[ ! -b "$LUKS_DEV" ]]; then
    LUKS_DEV="${disk}2"
    ESP_DEV="${disk}1"
  fi
  if [[ -b "$LUKS_DEV" ]]; then
    if ! echo -n "$luks_pass" | cryptsetup open "$LUKS_DEV" crypted --key-file -; then
      echo "Wrong LUKS passphrase; set danny password after boot: passwd danny"
    else
      mount /dev/mapper/crypted /mnt
      [[ -b "$ESP_DEV" ]] && mount "$ESP_DEV" /mnt/boot
      mount --bind /dev /mnt/dev
      mount --bind /proc /mnt/proc
      mount --bind /sys /mnt/sys
      echo "danny:${danny_pass}" | chroot /mnt chpasswd
      umount -R /mnt
      cryptsetup close crypted
      echo "Password for danny set. Reboot and log in."
    fi
    unset luks_pass
  else
    echo "Could not find LUKS partition; set password after boot: passwd danny"
  fi
fi
