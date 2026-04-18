{ inputs, config, ... }: {
  flake.nixosConfigurations.phantom-ship = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.nix-openclaw.nixosModules.openclaw-gateway
      ../hosts/phantom-ship.nix
      config.flake.nixosModules.dotfiles-rebuild

      inputs.home-manager.nixosModules.home-manager
      (import ../lib/home-manager-user.nix {
        lib = inputs.nixpkgs.lib;
        user = "danny";
        homeDirectory = "/home/danny";
        stateVersion = "25.11";
      })
    ];
  };
}
