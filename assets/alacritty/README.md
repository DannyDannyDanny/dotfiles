# Unified Theme Switching

Unified theme switching that works across platforms (WSL and macOS) for Neovim, Alacritty, and Windows Terminal.

**This solution uses a single `theme` command that detects the platform and switches themes appropriately.**

## How It Works

1. The `theme` command detects the platform (WSL vs macOS)
2. **On WSL:** Updates Neovim, Windows Terminal, and Windows system theme
3. **On macOS:** Updates Neovim and Alacritty themes via Nix configuration
4. Uses the same `nvim_color_scheme` file for Neovim on both platforms

## Setup

1. **The configuration is already set up!** The `theme` command is available as a fish alias.

2. **To switch themes, use the unified command:**
   ```bash
   theme light   # Switch to light theme
   theme dark    # Switch to dark theme
   ```

## Usage

### Unified Theme Command
```bash
# Switch to light theme (works on WSL and macOS)
theme light

# Switch to dark theme (works on WSL and macOS)
theme dark
```

### What Gets Updated

**On WSL:**
- Neovim theme (via `~/.local/share/nvim_color_scheme`)
- Windows Terminal settings
- Windows system theme
- Windows sound scheme

**On macOS:**
- Neovim theme (via `~/.local/share/nvim_color_scheme`)
- Alacritty theme (via Nix configuration)

### Manual Configuration (macOS only)
You can also manually edit `nixos/home/danny/home.nix` and change:
```nix
isLightTheme = true;   # for light theme
isLightTheme = false;  # for dark theme
```
Then run: `cd nixos && sudo darwin-rebuild switch --flake .#Daniel-Macbook-Air`

## Files

- `scripts/theme.sh` - **Main unified theme switching script**
- `scripts/switch-alacritty-theme.sh` - Alacritty-specific theme switching (used by theme.sh)
- `scripts/detect-system-theme.sh` - Detects current macOS system theme (for reference)
- `nixos/fish.nix` - Contains the `theme` fish alias
- `nixos/home/danny/home.nix` - Contains the conditional Alacritty configuration
- `bashscripts/wsl_theme.sh` - Legacy WSL script (replaced by theme.sh)

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