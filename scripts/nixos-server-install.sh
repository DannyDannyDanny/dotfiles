#!/usr/bin/env bash
# Run on a NixOS minimal live system (or installer ISO) to install NixOS with
# disko (LUKS + root). Prompts for hostname and target disk; optionally use
# INSTALLER_SYSTEM_CONFIG_FILE for WiFi etc.
#
# Usage:
#   Export FLAKE_REF (e.g. github:User/dotfiles or path:/path/to/dotfiles/nixos).
#   Or run from repo root and use: FLAKE_REF=path:$(pwd)/nixos
#   sudo ./scripts/nixos-server-install.sh
#   # or: sudo FLAKE_REF=github:User/dotfiles ./scripts/nixos-server-install.sh
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

echo "Flake:      ${FLAKE_REF}#server-install"
echo "Disk:       $disk"
echo "Hostname:   $hostname"
echo "System config: $SYSTEM_CONFIG"
read -r -p "Proceed? [y/N] " confirm
if [[ "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

exec nix run github:nix-community/disko/latest#disko-install -- \
  --flake "${FLAKE_REF}#server-install" \
  --disk main "$disk" \
  --system-config "$SYSTEM_CONFIG"
