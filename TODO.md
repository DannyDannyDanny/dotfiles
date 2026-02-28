# TODO

1. **Secrets** (started)
   - SSH public keys removed from `nixos/hosts/nixos-server.nix` and `nixos/server-install-configuration.nix`. Keys are not managed by NixOS there; use scp (see comments in those files and server-quickstart.md).
   - Optional: audit repo for other IDs (emails, UUIDs) if desired.
   - Check out friend's setup: public repo w config + setup; private repo w IDs, keys and secrets.
   - **SSH keys (one key per purpose).** Strategy: AGENTS.md. Actions:
     - **GitHub:** In use: `id_ed25519_github`. Add `~/.ssh/config`: `Host github.com` with `IdentityFile ~/.ssh/id_ed25519_github` and `IdentitiesOnly yes`. Remove `id_rsa_github` from GitHub and locally once confirmed unused.
     - **nixos-server:** No `~/.ssh/authorized_keys` on server → currently password auth. To switch to key auth: on server `mkdir -p ~/.ssh; chmod 700 ~/.ssh`; from Mac `scp ~/.ssh/id_ed25519_github.pub danny@SERVER:/tmp/`; on server `cat /tmp/id_ed25519_github.pub >> ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys`. Optional: create `id_ed25519_servers` and use that only for server (then add Host in config).
     - **Forgejo:** When needed: create `id_ed25519_forgejo`, add to forge, add Host in `~/.ssh/config`.

2. ~~**Server hardware before testing**~~ Done. Fetched via `ssh danny@server 'sudo cat /etc/nixos/hardware-configuration.nix'`, replaced stub; added boot.loader and system.stateVersion; flake check passes.

3. **Server**
   - Continue configuring the server (add more services to `hosts/nixos-server.nix` as needed).
   - Make sure SSH is only possible via LAN, using ssh keys and no password
   - Make sudo not require a password

4. **Verify**
   - After 2–4: confirm server hardware in repo, flake builds, auto-rebuild works. On server, `systemctl is-active dotfiles-rebuild.timer` should be `active` once the flake config is live (see nixos/readme.md).

5. Rename nixos-server to <something-cooler>

6. Give <something-cooler> wifi access in stead of using ethernet.

7. Host telegram bot once again (for what purpose?)
