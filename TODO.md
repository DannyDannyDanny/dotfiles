# TODO

1. **Secrets** — Approach A (see [docs/ssh-and-secrets.md](docs/ssh-and-secrets.md)): public repo only, one key per purpose (AGENTS.md), server keys via scp. Optional later: private repo + sops-nix.
   - **GitHub:** Use `id_ed25519_github`; in `~/.ssh/config`: `Host github.com` with `IdentityFile ~/.ssh/id_ed25519_github` and `IdentitiesOnly yes`. Remove `id_rsa_github` from GitHub and locally once confirmed unused.
   - **nixos-server:** Switch to key auth if still on password: on server `mkdir -p ~/.ssh; chmod 700 ~/.ssh`; from Mac `scp ~/.ssh/id_ed25519_github.pub danny@SERVER:/tmp/`; on server `cat /tmp/id_ed25519_github.pub >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys`. Optional: create `id_ed25519_servers` and use only for servers (add Host in config).
   - **Forgejo:** When needed: create `id_ed25519_forgejo`, add to forge, add Host in `~/.ssh/config`.

2. **Server**
   - Only I use the machine. Access: SSH keys only (no password auth).
   - Continue configuring (add services in `hosts/nixos-server.nix` as needed).
   - SSH: key-only auth; disable password auth. Optionally restrict SSH to LAN.
   - Passwordless sudo for wheel.

3. Rename nixos-server to <something-cooler>
   - Shortlist hostnames; then do flake + hostname + docs in one pass.
   - **Monte Cristo–themed candidates (two-word, non-human):**
     - Ships / sea: sunken-ship, phantom-ship, rusty-anchor, salty-wind, stormy-wave, calm-harbor, distant-shore, foreign-port, wooden-hull, anchor-chain
     - Prison / stone: prison-rock, cold-stone, iron-chain, damp-cell, guard-tower, midnight-bell, stony-corridor, broken-chain
     - Secrets / treasure: buried-treasure, secret-cave, forgotten-tunnel, hidden-key, rusty-sword, faded-parchment, ancient-map, broken-seal, buried-chest
     - Atmosphere: strange-companion, masked-ball, poison-vial

4. Give <something-cooler> wifi access instead of ethernet.

5. Host telegram bot once again (for what purpose?)
