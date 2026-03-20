# CLAUDE.md

## Build commands

```bash
# macOS (from ~/dotfiles/nixos)
darwin-rebuild switch --flake .

# NixOS server (SSH from mac, or on server)
sudo nixos-rebuild switch --flake .#sunken-ship

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
- **Inputs:** nixpkgs-unstable, nix-darwin, home-manager, nixos-wsl, disko, zen-browser, nix-openclaw, openclaw-documents
- **Host configs** in `nixos/hosts/`:
  - `macos.nix` — Apple Silicon MacBook Air (aarch64-darwin, nix-darwin)
  - `sunken-ship.nix` — NixOS home server (x86_64-linux)
  - `wsl.nix` — WSL (x86_64-linux)
  - `macbookair.nix` — old MacBook Air NixOS/WSL config
  - `server-install.nix` — disko-install target (LUKS + WiFi)
- **Home Manager:** integrated via `home-manager.darwinModules.home-manager` on macOS; user config in `nixos/home/danny/home.nix`
- **Shared modules:** `nixos/fish.nix` (fish + bash), `nixos/tmux.nix`, `nixos/ollama.nix`
- **Darwin config name:** `Daniel-Macbook-Air` (must match in rebuild commands)

## Repo rules

- **Public repo** — no keys, tokens, or identifying secrets. Use `scp` or config outside the repo.
- **SSH keys:** one key per purpose (e.g. `id_ed25519_github`, `id_ed25519_servers`). Use `IdentityFile` + `IdentitiesOnly yes` in `~/.ssh/config`. Keys stay outside the repo.
- **Commit and push** before testing on sunken-ship — the server clones/pulls from origin.

## Server (sunken-ship)

- SSH: `ssh -i ~/.ssh/id_ed25519_sunken_ship danny@sunken-ship`
- Remote rebuild: `ssh ... 'cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#sunken-ship'`
- Auto-rebuild timer: `dotfiles-rebuild` — only active after flake config switch. Check with `systemctl is-active dotfiles-rebuild.timer`.
- Server has WiFi; stays reachable when ethernet is unplugged.

## OpenClaw

AI assistant gateway (Telegram), integrated in the flake. Config: `nixos/home/danny/openclaw.nix`. Documents (SOUL.md, TOOLS.md) come from a separate local repo via the `openclaw-documents` flake input (path: `/Users/danny/dotfiles/openclaw-documents-repo`). Secrets (bot token, gateway token, Telegram user ID) live in `~/.secrets/` or the config. One apply: `darwin-rebuild switch --flake .`.

## Ollama

Custom nix-darwin module at `nixos/ollama.nix` (upstream PR not yet merged). Enabled on macOS via `nixos/hosts/macos.nix`. Runs as a launchd user agent with `ollama serve`.

## Shell

Fish is the default shell. Bash auto-execs fish unless the parent process is already fish. Vi keybindings with fzf integration. Zoxide aliased to `cd`.
