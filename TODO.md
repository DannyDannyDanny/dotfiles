# TODO

1. **Secrets** — Approach A (see [docs/ssh-and-secrets.md](docs/ssh-and-secrets.md)): public repo only, one key per purpose (AGENTS.md), server keys via scp. Optional later: private repo + sops-nix.
   - **GitHub:** Use `id_ed25519_github`; in `~/.ssh/config`: `Host github.com` with `IdentityFile ~/.ssh/id_ed25519_github` and `IdentitiesOnly yes`. Remove `id_rsa_github` from GitHub and locally once confirmed unused.
   - **sunken-ship:** Switch to key auth if still on password: on server `mkdir -p ~/.ssh; chmod 700 ~/.ssh`; from Mac `scp ~/.ssh/id_ed25519_github.pub danny@SERVER:/tmp/`; on server `cat /tmp/id_ed25519_github.pub >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys`. Optional: create `id_ed25519_servers` and use only for servers (add Host in config).
   - **Forgejo:** When needed: create `id_ed25519_forgejo`, add to forge, add Host in `~/.ssh/config`.

2. **Server**
   - Only I use the machine. Access: SSH keys only (no password auth).
   - Continue configuring (add services in `hosts/sunken-ship.nix` as needed).
   - SSH: key-only auth; disable password auth. Optionally restrict SSH to LAN.
   - Passwordless sudo for wheel.

3. ~~Rename nixos-server to sunken-ship~~ Done.

4. Give <something-cooler> wifi access instead of ethernet.

5. Host telegram bot once again (for what purpose?)
