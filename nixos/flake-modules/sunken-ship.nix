{ inputs, config, ... }: {
  flake.nixosConfigurations.sunken-ship = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ../hosts/sunken-ship.nix
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
