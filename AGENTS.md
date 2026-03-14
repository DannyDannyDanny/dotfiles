# Agent Instructions

## Nix/Darwin Rebuilds

**IMPORTANT**: When making changes to Nix configuration files (e.g., `nixos/home/danny/home.nix`, `nixos/flake.nix`, etc.), **always ask the user to rebuild** before assuming packages are available.

To rebuild:
```bash
cd ~/dotfiles/nixos
darwin-rebuild switch --flake .
```

Do not automatically run rebuild commands - ask the user first.

## Repo is public

No keys, tokens, or identifying secrets in the repo. Prefer `scp` or config outside the repo.

## SSH keys (one key per purpose)

We use **one key per purpose**, not one per machine: separate keys for server access, GitHub, Forgejo (and other forges if needed). Benefits: limit blast radius if a key is compromised; clear revocation; clear which key is for what.

- **Key names:** e.g. `id_ed25519_github`, `id_ed25519_forgejo`, `id_ed25519_servers` (Ed25519 preferred).
- **Config:** Use `~/.ssh/config` with `IdentityFile` and `IdentitiesOnly yes` per host so the right key is used. Keys and sensitive config stay outside the repo.
- **Server / NixOS:** Use actual key names on the machine (e.g. `id_ed25519_github`), not a generic `id_ed25519` (see Learnings below).

## Server installer USB (new machines only)

- Build: from **Linux** `cd ~/dotfiles/nixos && nix build .#installer-iso` (ISO is x86_64-linux only; cannot build on macOS). Or use official NixOS minimal ISO, write to USB, boot server, clone repo, run [scripts/nixos-server-install.sh](scripts/nixos-server-install.sh). See [docs/server-installer-usb.md](docs/server-installer-usb.md). Optional live WiFi: add `nixos/installer-wifi.nix` (gitignored) when building custom ISO on Linux.

## Learnings (NixOS server)

- Minimal ISO: use Ethernet or the graphical installer (Wi‑Fi on minimal is fiddly).
- Server hardware: stub in repo; user replaces with `nixos-generate-config --show-hardware-config` from the server.
- Root password: console only; set danny’s password as root once for sudo.
- SSH keys: use actual key names on the machine (e.g. `id_ed25519_github`), not assumed `id_ed25519`.

## Server (sunken-ship)

- **Commit and push** before testing on the server; it clones/pulls from origin.
- Bootstrap: server has no git until first rebuild. Use `nix run --extra-experimental-features "nix-command flakes" nixpkgs#git` to clone. Enable flakes in the daemon via `server-configuration-with-flakes.nix`: scp to server `/tmp/configuration.nix`, on server `sudo cp` to `/etc/nixos/configuration.nix`, then `sudo nixos-rebuild switch`. Then build flake and run `switch-to-configuration switch` (see nixos/readme.md).
- Auto-rebuild timer (`dotfiles-rebuild`) only runs after the system has been switched to the flake config. Check with `systemctl is-active dotfiles-rebuild.timer` on the server.

### Running commands on sunken-ship

From the Mac (where the dotfiles workspace lives), agents can SSH to sunken-ship to run commands. Use the sunken-ship key and the host alias or IP the user has configured (e.g. `ssh -i ~/.ssh/id_ed25519_sunken_ship danny@sunken-ship` or `danny@192.168.1.x`). Example:

```bash
ssh -i ~/.ssh/id_ed25519_sunken_ship danny@sunken-ship 'hostname; ip addr'
```

Rebuild on the server (flake is in `nixos/`): `ssh ... 'cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#sunken-ship'`. The server has WiFi (see [docs/sunken-ship-wifi.md](docs/sunken-ship-wifi.md)); it remains reachable when ethernet is unplugged.

## OpenClaw (macOS)

OpenClaw (AI assistant gateway, Telegram) is integrated in the dotfiles flake. Config: [nixos/home/danny/openclaw.nix](nixos/home/danny/openclaw.nix). Documents: [nixos/home/danny/openclaw-documents/](nixos/home/danny/openclaw-documents/). Secrets (bot token, gateway token, Telegram user ID) live in the config or `~/.secrets/`. One apply: `darwin-rebuild switch --flake .` from `nixos/`.

