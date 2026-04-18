{ inputs, ... }: {
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.default
      inputs.vscode-server.nixosModules.default
      ../hosts/wsl.nix
      ../fish.nix

      # Home Manager on WSL
      inputs.home-manager.nixosModules.home-manager
      ({ lib, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "backup";
        home-manager.users.dth = { ... }: {
          home.username = "dth";
          home.homeDirectory = lib.mkForce "/home/dth";
          imports = [ ../home/danny/home.nix ];
        };
      })
    ];
  };
}
