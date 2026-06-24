# TODO

- [ ] **Drop brew --force-cleanup workaround**: once [nix-darwin#1789](https://github.com/nix-darwin/nix-darwin/pull/1789) merges, `nix flake update nix-darwin` and remove `homebrew.onActivation.extraFlags = [ "--force-cleanup" ]` from `daniel-macbook-air.nix` (Homebrew ≥5.1 requires a force flag with `--cleanup`; upstream fix passes it natively).

> Fleet/server TODOs (installer USB, server encryption, alerting, etc.) live in the private `homelab` repo.
