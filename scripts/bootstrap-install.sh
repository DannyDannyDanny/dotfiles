#!/bin/bash
# Fetch with curl and run to install NixOS (clone + run nixos-server-install.sh).
# On the live system, run only:
#   curl -sL https://raw.githubusercontent.com/DannyDannyDanny/dotfiles/server-installer-usb/scripts/bootstrap-install.sh | sudo bash
#
# Optional: REPO_URL=... BRANCH=... (default repo and server-installer-usb)
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/DannyDannyDanny/dotfiles.git}"
BRANCH="${BRANCH:-server-installer-usb}"
DEST="/tmp/dotfiles"
INSTALL_SCRIPT="$DEST/scripts/nixos-server-install.sh"

if [[ ! -f "$INSTALL_SCRIPT" ]]; then
  echo "Cloning $REPO_URL ($BRANCH) to $DEST..."
  nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone --branch "$BRANCH" "$REPO_URL" "$DEST"
fi

cd "$DEST"
# Use /dev/tty for stdin so prompts work when bootstrap is run as: curl ... | sudo bash
[[ "$EUID" -ne 0 ]] && exec sudo bash "$INSTALL_SCRIPT" < /dev/tty
exec bash "$INSTALL_SCRIPT" < /dev/tty
