{ inputs, ... }: {
  flake.nixosConfigurations.phantom-ship = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.nix-openclaw.nixosModules.openclaw-gateway
      ../hosts/phantom-ship.nix

      # Home Manager on NixOS
      inputs.home-manager.nixosModules.home-manager
      ({ lib, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.users.danny = { ... }: {
          home.username = "danny";
          home.homeDirectory = lib.mkForce "/home/danny";
          home.stateVersion = "25.11";
        };
      })
    ];
  };
}
