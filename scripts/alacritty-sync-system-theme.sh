#!/usr/bin/env bash
# Keep Alacritty in sync with macOS light/dark appearance.
# No Nix rebuild: copies a palette into active-colors.toml; Alacritty reloads via live_config_reload.

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ALACRITTY_DIR="$XDG_CONFIG_HOME/alacritty"
ACTIVE="$ALACRITTY_DIR/active-colors.toml"
MARKER="$ALACRITTY_DIR/.last-system-theme"

LIGHT="$ALACRITTY_DIR/catppuccin-latte-colors.toml"
DARK="$ALACRITTY_DIR/catppuccin-mocha-colors.toml"

if [[ ! -f "$LIGHT" || ! -f "$DARK" ]]; then
  echo "alacritty-sync-system-theme: missing $LIGHT or $DARK (run home-manager switch first)" >&2
  exit 1
fi

appearance="$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)"
if [[ "$appearance" == "Dark" ]]; then
  want="dark"
else
  want="light"
fi

mkdir -p "$ALACRITTY_DIR"
printf '%s' "$want" >"$MARKER"

if [[ "$want" == "light" ]]; then
  tmp="$(mktemp "$ALACRITTY_DIR/active-colors.toml.XXXXXX")"
  cp "$LIGHT" "$tmp"
else
  tmp="$(mktemp "$ALACRITTY_DIR/active-colors.toml.XXXXXX")"
  cp "$DARK" "$tmp"
fi

chmod 0644 "$tmp"
mv -f "$tmp" "$ACTIVE"
