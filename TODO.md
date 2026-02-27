# TODO

1. **Secrets** (started)
   - SSH public keys removed from `nixos/hosts/nixos-server.nix` and `nixos/server-install-configuration.nix`. Keys are not managed by NixOS there; use scp (see comments in those files and server-quickstart.md).
   - Optional: audit repo for other IDs (emails, UUIDs) if desired.

2. ~~**Server hardware before testing**~~ Done. Fetched via `ssh danny@server 'sudo cat /etc/nixos/hardware-configuration.nix'`, replaced stub; added boot.loader and system.stateVersion; flake check passes.

3. **Server**
   - Continue configuring the server (add more services to `hosts/nixos-server.nix` as needed).

4. **Verify**
   - After 2–4: confirm server hardware in repo, flake builds, auto-rebuild works.

5. Rename nixos-server to <something-cooler>