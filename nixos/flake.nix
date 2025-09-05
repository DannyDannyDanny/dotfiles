{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # nix-darwin for macOS
    # (follows nixpkgs so both use the same channel)
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # for later
    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    vscode-server,
    nix-darwin,
    self,
    # home-manager,
    ...
  }: {
    nixosConfigurations = {
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          vscode-server.nixosModules.default
          ./hosts/wsl.nix
          ./tmux.nix
          ./neovim.nix
          ./fish.nix
          # home-manager.nixosModules.default
        ];
      };

      macbookair = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModules.default
          ./hosts/macbookair.nix
          ./hardware-configuration.nix
          ./tmux.nix
          ./neovim.nix
          ./fish.nix
          # home-manager.nixosModules.default
          # ./configuration.nix
          # ./uxplay.nix
        ];
      };
    };

    # macOS (nix-darwin) configuration
    darwinConfigurations."Daniel-Macbook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        # Ensure Apple Silicon platform
        { nixpkgs.hostPlatform = "aarch64-darwin"; }

        # Your macOS module (you created it under nixos/hosts/macos.nix)
        ./nixos/hosts/macos.nix
      ];
    };
  };
}
