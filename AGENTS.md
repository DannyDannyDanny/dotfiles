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

## Learnings (NixOS server)

- Minimal ISO: use Ethernet or the graphical installer (Wi‑Fi on minimal is fiddly).
- Server hardware: stub in repo; user replaces with `nixos-generate-config --show-hardware-config` from the server.
- Root password: console only; set danny’s password as root once for sudo.
- SSH keys: use actual key names on the machine (e.g. `id_ed25519_github`), not assumed `id_ed25519`.

