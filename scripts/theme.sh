#!/bin/bash

# Unified theme switching script for WSL and macOS
# This script handles theme switching for both platforms

set -e

color_scheme=$1

# Validate user input
if [[ "$color_scheme" != "dark" && "$color_scheme" != "light" ]]; then
  echo "Usage: theme {dark|light}"
  echo ""
  echo "This command switches themes for:"
  echo "  - Neovim (via nvim_color_scheme file)"
  echo "  - Alacritty (via Nix configuration on macOS)"
  echo "  - Windows Terminal (via settings.json on WSL)"
  echo "  - Windows system theme (on WSL)"
  exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Write theme to nvim color scheme file (works on both platforms)
nvim_color_theme_path=~/.local/share/nvim_color_scheme
mkdir -p "$(dirname "$nvim_color_theme_path")"
echo "$color_scheme" > "$nvim_color_theme_path"
echo "Updated Neovim theme: $color_scheme"

# Detect platform and handle platform-specific theme switching
if [[ -n "$WSL_DISTRO_NAME" ]]; then
  # WSL platform - handle Windows Terminal and system theme
  echo "Detected WSL platform"
  
  # Check that all relevant files exist
  windows_username=$(powershell.exe '$env:UserName' | tr -d '\r\n')
  windows_terminal_settings_path="/mnt/c/Users/${windows_username}/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
  dark_mode_config_path="$DOTFILES_DIR/assets/windows_terminal/dark.settings.json"
  light_mode_config_path="$DOTFILES_DIR/assets/windows_terminal/light.settings.json"

  if [ ! -f "$light_mode_config_path" ]; then
    echo "error: light_mode_config_path missing"
    echo "expected: $light_mode_config_path"
    exit 1
  fi

  if [ ! -f "$dark_mode_config_path" ]; then
    echo "error: dark_mode_config_path missing"
    echo "expected: $dark_mode_config_path"
    exit 1
  fi

  if [ ! -f "$windows_terminal_settings_path" ]; then
    echo "error: windows terminal settings path missing"
    echo "expected: $windows_terminal_settings_path"
    exit 1
  fi

  # Update Windows Terminal settings
  if [ "$color_scheme" = 'dark' ]; then
    cp "$dark_mode_config_path" "$windows_terminal_settings_path"
    echo "Updated Windows Terminal: dark theme"
    echo "Switching Windows system theme to dark..."
    powershell.exe -Command "start C:\Windows\Resources\Themes\dark.theme"
    powershell.exe "timeout /t 3; taskkill /im systemsettings.exe /f"
  else
    cp "$light_mode_config_path" "$windows_terminal_settings_path"
    echo "Updated Windows Terminal: light theme"
    echo "Switching Windows system theme to light..."
    powershell.exe -Command "start C:\Windows\Resources\Themes\aero.theme"
    powershell.exe "timeout /t 3; taskkill /im systemsettings.exe /f"
  fi

  echo "Setting Sound Schema to None"
  powershell.exe -Command "Set-ItemProperty -Path HKCU:\AppEvents\Schemes -Name '(Default)' -Value '.None'"

elif [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS platform - handle Alacritty theme
  echo "Detected macOS platform"
  
  # Use the existing Alacritty theme switching script
  alacritty_script="$DOTFILES_DIR/scripts/switch-alacritty-theme.sh"
  if [ -f "$alacritty_script" ]; then
    echo "Switching Alacritty theme to: $color_scheme"
    "$alacritty_script" "$color_scheme"
  else
    echo "Warning: Alacritty theme script not found at $alacritty_script"
    echo "Theme file updated, but Alacritty theme not switched"
  fi

else
  # Other platforms - just update the theme file
  echo "Detected other platform - only updating Neovim theme file"
fi

echo "Theme switching complete: $color_scheme"
