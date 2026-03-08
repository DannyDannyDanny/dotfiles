#!/usr/bin/env bash
# Build the NixOS installer ISO on sunken-ship (x86_64-linux) and copy it back.
# Run from your Mac when sunken-ship is reachable (same network).
# Usage: ./scripts/build-installer-iso-on-server.sh [host] [output_dir]
#   host: SSH host (default: sunken-ship)
#   output_dir: where to save the ISO on your Mac (default: .)
# Override SSH key: SSH_KEY=~/.ssh/my_key ./scripts/build-installer-iso-on-server.sh
set -euo pipefail

HOST="${1:-sunken-ship}"
OUT="${2:-.}"

# Use sunken-ship key if not set (AGENTS.md)
if [[ -n "${SSH_KEY:-}" ]]; then
  SSH_OPTS=(-i "$SSH_KEY")
elif [[ "$HOST" == "sunken-ship" ]] && [[ -f ~/.ssh/id_ed25519_sunken_ship ]]; then
  SSH_OPTS=(-i ~/.ssh/id_ed25519_sunken_ship)
else
  SSH_OPTS=()
fi

echo "Pushing branch so server can pull..."
git push origin server-installer-usb 2>/dev/null || true

echo "On $HOST: clone branch, build ISO..."
ssh "${SSH_OPTS[@]}" "$HOST" 'set -e
  BUILD_DIR=~/dotfiles-iso-build
  rm -rf "$BUILD_DIR"
  git clone --branch server-installer-usb https://github.com/DannyDannyDanny/dotfiles.git "$BUILD_DIR"
  cd "$BUILD_DIR/nixos"
  nix build .#installer-iso
  ls -la result/iso/
'

ISO_NAME=$(ssh "${SSH_OPTS[@]}" "$HOST" 'ls ~/dotfiles-iso-build/nixos/result/iso/*.iso 2>/dev/null | head -1')
ISO_NAME=$(basename "$ISO_NAME")

echo "Copying $ISO_NAME to $OUT ..."
scp "${SSH_OPTS[@]}" "$HOST:~/dotfiles-iso-build/nixos/result/iso/$ISO_NAME" "$OUT/"
echo "Done. ISO at $OUT/$ISO_NAME"
echo "Write to USB: diskutil unmountDisk diskN && sudo dd if=$OUT/$ISO_NAME of=/dev/rdiskN bs=4m"
