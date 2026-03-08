# Server TODO and SSH key for sunken-ship

## Scope

- **Server TODO** (TODO.md §2): Configure sunken-ship with SSH key-only auth, disable password auth, optional LAN restriction, passwordless sudo for wheel.
- **SSH key**: Create a **new key for server access**, and specifically **a new key for sunken-ship** (e.g. `id_ed25519_sunken_ship`), not a shared "servers" key. One key dedicated to sunken-ship.

## Tasks

1. **Create key**: On Mac, run:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_sunken_ship -N "" -C "danny@sunken-ship"
   ```
   Keep private key local, never in repo. Use a passphrase instead of `-N ""` if you prefer.
2. **Secrets (TODO §1)**: Update sunken-ship bullet to use the new key: scp the public key to the server, add to `~/.ssh/authorized_keys` on server, add `Host sunken-ship` in `~/.ssh/config` with `IdentityFile ~/.ssh/id_ed25519_sunken_ship` and `IdentitiesOnly yes`.
3. **Server (TODO §2)**: NixOS config in `hosts/sunken-ship.nix`: enable OpenSSH, disable password authentication, optionally restrict to LAN; ensure passwordless sudo for wheel. Authorized keys are not managed by Nix; they are added via scp as above.

## Done

- Key created: `~/.ssh/id_ed25519_sunken_ship` (and `.pub`). Keep private key local; never commit.
- [nixos/hosts/sunken-ship.nix](../nixos/hosts/sunken-ship.nix): SSH password auth disabled, passwordless sudo for wheel.

## Next steps (you do these)

1. **Add your public key to sunken-ship** (do this before rebuilding, or you may lock yourself out if password auth is already off):
   - On server: `mkdir -p ~/.ssh; chmod 700 ~/.ssh`
   - From Mac: `scp ~/.ssh/id_ed25519_sunken_ship.pub danny@SUNKEN_SHIP_IP_OR_HOST:/tmp/`
   - On server: `cat /tmp/id_ed25519_sunken_ship.pub >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys`

2. **Add to `~/.ssh/config`** (config stays outside repo):
   ```
   Host sunken-ship
     HostName YOUR_SERVER_IP_OR_HOSTNAME
     User danny
     IdentityFile ~/.ssh/id_ed25519_sunken_ship
     IdentitiesOnly yes
   ```

3. **Rebuild the server** so the new NixOS config (no password auth, passwordless sudo) applies. From your Mac, after commit & push: `ssh sunken-ship 'cd /etc/dotfiles && sudo nixos-rebuild switch --flake .#sunken-ship'` (or use the hostname you use for the server). Per AGENTS.md: commit and push first; the server pulls from origin.

## References

- [TODO.md](../TODO.md) — Secrets §1 (sunken-ship), Server §2
- [AGENTS.md](../AGENTS.md) — SSH key naming; keys outside repo
- [ssh-and-secrets.md](ssh-and-secrets.md) — Approach A, scp workflow
- [nixos/hosts/sunken-ship.nix](../nixos/hosts/sunken-ship.nix) — Server NixOS config
