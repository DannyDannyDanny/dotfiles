# Alacritty Theme Synchronization

Simple theme switching for Alacritty that allows you to switch between Catppuccin light and dark themes.

**This solution uses Nix conditional configuration with a simple script to switch themes.**

## How It Works

1. The Nix configuration has a boolean variable `isLightTheme` in `home.nix`
2. When `isLightTheme = true` → Catppuccin Latte (light theme)
3. When `isLightTheme = false` → Catppuccin Mocha (dark theme)
4. A script updates this variable and rebuilds the configuration

## Setup

1. **The configuration is already set up!** Your Alacritty is currently using the light theme.

2. **To switch themes, use the script:**
   ```bash
   ./scripts/switch-alacritty-theme.sh light   # Switch to light theme
   ./scripts/switch-alacritty-theme.sh dark    # Switch to dark theme
   ./scripts/switch-alacritty-theme.sh toggle  # Toggle between themes
   ./scripts/switch-alacritty-theme.sh status  # Show current theme
   ```

## Usage

### Manual Theme Switching
```bash
# Switch to light theme
./scripts/switch-alacritty-theme.sh light

# Switch to dark theme  
./scripts/switch-alacritty-theme.sh dark

# Toggle between themes
./scripts/switch-alacritty-theme.sh toggle

# Check current theme
./scripts/switch-alacritty-theme.sh status
```

### Manual Configuration
You can also manually edit `nixos/home/danny/home.nix` and change:
```nix
isLightTheme = true;   # for light theme
isLightTheme = false;  # for dark theme
```
Then run: `cd nixos && sudo darwin-rebuild switch --flake .#Daniel-Macbook-Air`

## Files

- `scripts/switch-alacritty-theme.sh` - Script to switch themes
- `scripts/detect-system-theme.sh` - Detects current macOS system theme (for reference)
- `nixos/home/danny/home.nix` - Contains the conditional Alacritty configuration

## Theme Colors

### Catppuccin Latte (Light)
- Background: `#eff1f5` (base)
- Foreground: `#4c4f69` (text)
- Accent colors optimized for light backgrounds

### Catppuccin Mocha (Dark)
- Background: `#1e1e2e` (base)
- Foreground: `#cdd6f4` (text)
- Accent colors optimized for dark backgrounds

## Integration with NixOS

The solution uses Nix's conditional configuration in `home.nix`:

```nix
colors = let
  isLightTheme = true;  # Change this to switch themes
  
  lightColors = { /* Catppuccin Latte colors */ };
  darkColors = { /* Catppuccin Mocha colors */ };
in if isLightTheme then lightColors else darkColors;
```

This approach:
- ✅ Works with Spotlight/Applications folder launches
- ✅ No complex file reading or external dependencies
- ✅ Integrates cleanly with NixOS configuration
- ✅ Simple and reliable - just change a boolean and rebuild
- ✅ Easy to understand and maintain