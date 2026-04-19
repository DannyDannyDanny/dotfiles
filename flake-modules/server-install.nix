{ inputs, ... }: {
  # For disko-install: LUKS + WiFi; hostname/WiFi via --system-config.
  flake.nixosConfigurations.server-install = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.disko.nixosModules.disko
      ../nixos/disko-server.nix
      ../nixos/hosts/server-install.nix
    ];
  };
}
