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

## Learnings (NixOS server)

- Minimal ISO: use Ethernet or the graphical installer (Wi‑Fi on minimal is fiddly).
- Server hardware: stub in repo; user replaces with `nixos-generate-config --show-hardware-config` from the server.
- Root password: console only; set danny’s password as root once for sudo.
- SSH keys: use actual key names on the machine (e.g. `id_ed25519_github`), not assumed `id_ed25519`.

## Server (nixos-server)

- **Commit and push** before testing on the server; it clones/pulls from origin.
- Bootstrap: server has no git until first rebuild. Use `nix run --extra-experimental-features "nix-command flakes" nixpkgs#git` to clone. Enable flakes in the daemon via `server-configuration-with-flakes.nix`: scp to server `/tmp/configuration.nix`, on server `sudo cp` to `/etc/nixos/configuration.nix`, then `sudo nixos-rebuild switch`. Then build flake and run `switch-to-configuration switch` (see nixos/readme.md).
- Auto-rebuild timer (`dotfiles-rebuild`) only runs after the system has been switched to the flake config. Check with `systemctl is-active dotfiles-rebuild.timer` on the server.

