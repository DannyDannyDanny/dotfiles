# Tools

What the assistant can use and how.

- CLI tools and skills come from enabled plugins (see `nixos/home/danny/openclaw.nix` → `programs.openclaw.instances.default.plugins`).
- Add plugins there and run `darwin-rebuild switch --flake .` from ~/dotfiles/nixos to install new tools and skills.
