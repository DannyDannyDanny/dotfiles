# TODO

1. ~~**AGENTS.md**~~ Done.

2. **Secrets**
   - Make sure we're not exposing any information in the repo. Prefer pushing keys via `scp` rather than committing them.

3. **Server hardware before testing**
   - Before checking if the server flake setup works: do we need to fetch anything from the server? (e.g. a hardware file?)
   - The current `nixos/hosts/nixos-server-hardware.nix` is a stub, not based on the server's actual hardware. The repo's existing `hardware-configuration.nix` is for the MacBook. Fetch the server's config (e.g. `nixos-generate-config --show-hardware-config` on the server) and replace the stub.

4. **Server**
   - Continue configuring the server.

5. **Verify**
   - After 2–4: confirm server hardware in repo, flake builds, auto-rebuild works.
