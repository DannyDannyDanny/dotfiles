# Expose reusable NixOS modules via `flake.nixosModules`.
#
# Consume from a host's flake-module via:
#   modules = [ config.flake.nixosModules.dotfiles-rebuild ];
{ ... }: {
  flake.nixosModules.dotfiles-rebuild = ../modules/dotfiles-rebuild.nix;
  flake.nixosModules.server-debug-tools = ../modules/server-debug-tools.nix;
  flake.nixosModules.monitoring-node-exporter = ../modules/monitoring-node-exporter.nix;
  flake.nixosModules.monitoring-prometheus-server = ../modules/monitoring-prometheus-server.nix;
}
