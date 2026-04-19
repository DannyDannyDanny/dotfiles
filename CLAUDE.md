# CLAUDE.md

## Build commands

```bash
# macOS (from ~/dotfiles/nixos)
darwin-rebuild switch --flake .

# NixOS servers (SSH from mac, or on server)
sudo nixos-rebuild switch --flake .#sunken-ship
sudo nixos-rebuild switch --flake .#phantom-ship

# WSL
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#wsl

# Update flake + rebuild (fish alias: nixupdate)
cd ~/dotfiles/nixos && sudo nix flake update && sudo darwin-rebuild switch --flake ~/dotfiles/nixos#Daniel-Macbook-Air

# Installer ISO (Linux only, cannot build on macOS)
cd ~/dotfiles/nixos && nix build .#installer-iso
```

## Rebuild protocol

**Never run rebuild commands automatically.** When changing Nix config files, always ask the user to rebuild first. Do not assume packages are available until after a successful rebuild.

## Flake architecture

- **Flake:** `nixos/flake.nix` — single flake for all hosts
- **Inputs:** nixpkgs-unstable, nix-darwin, home-manager, nixos-wsl, disko, zen-browser
- **Host configs** in `nixos/hosts/`:
  - `daniel-macbook-air.nix` — hostname `Daniel-Macbook-Air` (aarch64-darwin, nix-darwin)
  - `sunken-ship.nix` — NixOS home server (x86_64-linux, WiFi + AirPlay)
  - `phantom-ship.nix` — NixOS home server (x86_64-linux, Ethernet)
  - `wsl.nix` — WSL (x86_64-linux)
  - `server-install.nix` — disko-install target (LUKS)
- **Home Manager:** integrated on macOS, WSL, and sunken-ship; user config in `nixos/home/danny/home.nix`
- **Shared modules:** `nixos/fish.nix` (fish + bash), `nixos/ollama.nix`
- **Darwin config name:** `Daniel-Macbook-Air` (must match in rebuild commands)

## Repo rules

- **Public repo** — no keys, tokens, or identifying secrets. Use `scp` or config outside the repo.
- **SSH keys:** one key per purpose (e.g. `id_ed25519_github`, `id_ed25519_servers`). Use `IdentityFile` + `IdentitiesOnly yes` in `~/.ssh/config`. Keys stay outside the repo.
- **Commit and push** before testing on sunken-ship — the server clones/pulls from origin.

## Server (sunken-ship)

- SSH: `ssh -i ~/.ssh/id_ed25519_sunken_ship danny@sunken-ship`
- Remote rebuild: `ssh ... 'cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#sunken-ship'`
- Auto-rebuild timer: `dotfiles-rebuild` — every 15 min. Check with `systemctl is-active dotfiles-rebuild.timer`.
- WiFi connected; stays reachable when ethernet is unplugged.
- Services: UxPlay (AirPlay receiver on Scarlett Solo)

## Server (phantom-ship)

- SSH: `ssh danny@phantom-ship`
- Remote rebuild: `ssh ... 'cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#phantom-ship'`
- Auto-rebuild timer: same pattern as sunken-ship.
- Ethernet only (no WiFi).

## Ollama

Custom nix-darwin module at `nixos/ollama.nix` (upstream PR not yet merged). Enabled on macOS via `nixos/hosts/daniel-macbook-air.nix`. Runs as a launchd user agent with `ollama serve`.

## Alacritty (macOS)

Terminal colors follow **System Settings → Appearance**: `programs.alacritty` imports `~/.config/alacritty/active-colors.toml`; `scripts/alacritty-sync-system-theme.sh` copies Catppuccin latte/mocha there when the OS mode changes. **nix-darwin** `launchd.user.agents.alacritty-system-theme` polls every 30s; **fish** runs the same script on interactive startup. After changing Nix, one `darwin-rebuild switch`. Details: `assets/alacritty/README.md`.

## clan.lol

**CLI invocation:** clan-cli is not installed globally. Run ad-hoc via:

```bash
nix run git+https://git.clan.lol/clan/clan-core#clan-cli -- machines list \
  --flake 'path:/Users/danny/dotfiles/nixos'
```

**Flake path quirk:** `--flake .` and `--flake git+…` both fail from a git worktree when the flake lives in a subdir (`nixos/`). Use `--flake 'path:…/nixos'` explicitly. May not be needed from the main checkout — retest.

**`enableRecommendedDefaults = false`:** we opted out fleet-wide because clan's defaults flip to `systemd-networkd` + `systemd-resolved` + `boot.initrd.systemd`, which breaks dnsmasq (NAT DNS on phantom-ship) and navidrome's resolv.conf bind-mount on sunken-ship. Revisit per-service in a later pass — the defaults also include handy extras (tcpdump, htop, curl, jq, nixos-facter). Option defined in `nixosModules/clanCore/defaults.nix` + `nixosModules/clanCore/networking.nix` inside the `clan-core` flake.

**Deployment:** `dotfiles-rebuild` timer (every 15 min pull) is still the source of truth. `clan machines update` works as a push escape hatch; dm-pull-deploy replaces the timer in a later stage.

## Shell

Fish is the default shell. Bash auto-execs fish unless the parent process is already fish. Vi keybindings with fzf integration. Zoxide aliased to `cd`.
