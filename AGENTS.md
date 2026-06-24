# Agent Instructions

See **CLAUDE.md** for build commands, rebuild protocol, flake architecture, repo
rules, and SSH key strategy.

This is the public **dev-machine** repo: macOS (nix-darwin) + WSL (NixOS) + the
shared home-manager dev environment. Fleet/homelab operations (servers, clan,
deploys, topology, secrets) live in the separate **private `homelab` repo**, not
here.

## Learnings

- SSH keys: use the actual key names on the machine (e.g. `id_ed25519_github`), not an assumed `id_ed25519`.
- Never run rebuild commands automatically — ask the user to rebuild after Nix changes.
- Drop the brew `--force-cleanup` workaround once nix-darwin#1789 merges (see TODO.md).
