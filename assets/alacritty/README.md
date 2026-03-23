# Alacritty + system appearance (macOS)

Alacritty follows **System Settings → Appearance** automatically. No `darwin-rebuild` when you change light/dark.

## How it works

1. Home Manager installs Catppuccin palettes as `~/.config/alacritty/catppuccin-{latte,mocha}-colors.toml` and a generated `alacritty.toml` that sets `general.import` to `active-colors.toml`.
2. `scripts/alacritty-sync-system-theme.sh` copies the matching palette to `active-colors.toml`. Alacritty’s `live_config_reload` picks it up immediately.
3. **nix-darwin** runs that script from a user LaunchAgent every 30s (`nixos/hosts/macos.nix`: `launchd.user.agents.alacritty-system-theme`). It is also installed on `PATH` as `alacritty-sync-system-theme`.
4. **Fish** runs the same script in the background when you open an interactive shell on Darwin, so changes apply quickly without waiting for the next poll.

## Optional manual LaunchAgent

If you are not using the nix-darwin agent, you can load `assets/launchd/com.user.alacritty-theme-sync.plist` (adjust paths if needed). **Do not** load both the nix-darwin agent and this plist or you will run two pollers.

If you previously used the old plist label `com.user.alacritty-theme-sync` and switch to nix-darwin only:

```bash
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.user.alacritty-theme-sync.plist 2>/dev/null || true
```

## `theme` command (Neovim / WSL)

The fish alias `theme` still updates `~/.local/share/nvim_color_scheme` (and Windows Terminal on WSL). On macOS, **Alacritty ignores** `theme light|dark` for terminal colors—it only follows System Settings. Neovim stays on whatever you set with `theme`; the Alacritty sync script does not touch the nvim file.

```bash
theme light    # Neovim (+ WSL terminal); macOS Alacritty unchanged (uses Appearance)
theme dark
theme toggle
theme status
```

## Files

- `assets/alacritty/catppuccin-latte-colors.toml` / `catppuccin-mocha-colors.toml` — palette fragments
- `scripts/alacritty-sync-system-theme.sh` — detect macOS appearance, copy palette, refresh nvim marker
- `scripts/sync-alacritty-theme.sh` — thin wrapper (backwards compatible)
- `nixos/home/danny/home.nix` — `programs.alacritty` + `xdg.configFile` for palettes
- `nixos/hosts/macos.nix` — LaunchAgent + `alacritty-sync-system-theme` in `environment.systemPackages`
- `nixos/fish.nix` — optional shell-open sync on Darwin

After changing Nix config, run `darwin-rebuild switch` once (see repo `AGENTS.md`).

## Theme colors

### Catppuccin Latte (Light)

- Background: `#eff1f5` (base)
- Foreground: `#4c4f69` (text)

### Catppuccin Mocha (Dark)

- Background: `#1e1e2e` (base)
- Foreground: `#cdd6f4` (text)
