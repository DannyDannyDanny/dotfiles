# Expose reusable NixOS modules via `flake.nixosModules`.
#
# Consume from a host's flake-module via:
#   modules = [ config.flake.nixosModules.dotfiles-rebuild ];
{ ... }: {
  flake.nixosModules.dotfiles-rebuild = ../modules/dotfiles-rebuild.nix;
}
