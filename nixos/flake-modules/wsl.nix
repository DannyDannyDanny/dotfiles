{ inputs, ... }: {
  flake.nixosConfigurations.wsl = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.nixos-wsl.nixosModules.default
      inputs.vscode-server.nixosModules.default
      ../hosts/wsl.nix
      ../fish.nix

      inputs.home-manager.nixosModules.home-manager
      (import ../lib/home-manager-user.nix {
        lib = inputs.nixpkgs.lib;
        user = "dth";
        homeDirectory = "/home/dth";
        userImports = [ ../home/danny/home.nix ];
      })
    ];
  };
}
