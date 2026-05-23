#!/usr/bin/env bash
# Build the NixOS installer ISO on sunken-ship (x86_64-linux) and copy it back.
# Run from your Mac when sunken-ship is reachable (same network).
# Usage: ./scripts/build-installer-iso-on-server.sh [host] [output_dir]
#   host: SSH host (default: sunken-ship)
#   output_dir: where to save the ISO on your Mac (default: .)
# Override SSH key: SSH_KEY=~/.ssh/my_key ./scripts/build-installer-iso-on-server.sh
#
# If nixos/installer-wifi.nix exists locally (gitignored), it is copied into
# the build and the ISO gets preconfigured live-system WiFi. flake-modules/
# installer-iso.nix auto-includes it via a builtins.pathExists check.
set -euo pipefail

HOST="${1:-sunken-ship}"
OUT="${2:-.}"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Default to the sunken-ship SSH key when targeting that host.
if [[ -n "${SSH_KEY:-}" ]]; then
  SSH_OPTS=(-i "$SSH_KEY")
elif [[ "$HOST" == "sunken-ship" ]] && [[ -f ~/.ssh/id_ed25519_sunken_ship ]]; then
  SSH_OPTS=(-i ~/.ssh/id_ed25519_sunken_ship)
else
  SSH_OPTS=()
fi

echo "Pushing main so the server can clone the latest..."
git -C "$REPO_ROOT" push origin main 2>/dev/null || true

echo "On $HOST: clone main into ~/dotfiles-iso-build..."
ssh "${SSH_OPTS[@]}" "$HOST" 'set -e
  BUILD_DIR=~/dotfiles-iso-build
  rm -rf "$BUILD_DIR"
  git clone --branch main https://github.com/DannyDannyDanny/dotfiles.git "$BUILD_DIR"
'

# Optional live-system WiFi: the module is gitignored, so a fresh clone never
# has it. Copy it in and stage it (git add -f) so the flake sees it -- a flake
# build only includes git-tracked files.
if [[ -f "$REPO_ROOT/nixos/installer-wifi.nix" ]]; then
  echo "Found nixos/installer-wifi.nix - including live-system WiFi in the ISO."
  scp "${SSH_OPTS[@]}" "$REPO_ROOT/nixos/installer-wifi.nix" \
    "$HOST:dotfiles-iso-build/nixos/installer-wifi.nix"
  ssh "${SSH_OPTS[@]}" "$HOST" 'cd ~/dotfiles-iso-build && git add -f nixos/installer-wifi.nix'
fi

echo "On $HOST: build ISO (flake is at the repo root)..."
ssh "${SSH_OPTS[@]}" "$HOST" 'set -e
  cd ~/dotfiles-iso-build
  nix build .#installer-iso
  ls -la result/iso/
'

ISO_NAME=$(ssh "${SSH_OPTS[@]}" "$HOST" 'ls ~/dotfiles-iso-build/result/iso/*.iso 2>/dev/null | head -1')
ISO_NAME=$(basename "$ISO_NAME")

echo "Copying $ISO_NAME to $OUT ..."
scp "${SSH_OPTS[@]}" "$HOST:dotfiles-iso-build/result/iso/$ISO_NAME" "$OUT/"
echo "Done. ISO at $OUT/$ISO_NAME"
echo "Write to USB: diskutil unmountDisk diskN && sudo dd if=$OUT/$ISO_NAME of=/dev/rdiskN bs=4m"
