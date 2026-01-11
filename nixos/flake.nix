{
  inputs = {



    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    vscode-server,
    nix-darwin,
    self,
    home-manager,
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
          # TODO: handle all user-level programs via home-manager
          # ./neovim.nix  # Now handled via home-manager
          ./fish.nix
          # home-manager.nixosModules.default
        ];
      };

      macbookair = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          vscode-server.nixosModules.default
          vscode-server.nixosModules.default
          ./hosts/macbookair.nix
          ./hardware-configuration.nix
          ./tmux.nix
          # TODO: handle all user-level programs via home-manager
          # ./neovim.nix  # Now handled via home-manager
          ./fish.nix
          # home-manager.nixosModules.default
        ];
      };
    };

    # macOS (nix-darwin) configuration
    darwinConfigurations."Daniel-Macbook-Air" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/macos.nix
        ./fish.nix

        # Home Manager on macOS
        home-manager.darwinModules.home-manager
        ({ lib, ... }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.danny = { ... }: {

            # Force an absolute path even if another module sets a bad value.
            home.username = "danny";
            home.homeDirectory = lib.mkForce "/Users/danny";
            imports = [ ./home/danny/home.nix ];
          };
        })
      ];
    };
  };
}
