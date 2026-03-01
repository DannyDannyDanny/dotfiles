{
  inputs = {



    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    vscode-server,
    nix-darwin,
    self,
    home-manager,
    zen-browser,
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
          ./hosts/macbookair.nix
          ./hardware-configuration.nix
          ./tmux.nix
          # TODO: handle all user-level programs via home-manager
          # ./neovim.nix  # Now handled via home-manager
          ./fish.nix
          # home-manager.nixosModules.default
        ];
      };

      sunken-ship = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/sunken-ship.nix ];
      };
    };

    # macOS (nix-darwin) configuration
    darwinConfigurations."Daniel-Macbook-Air" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit zen-browser; };
      modules = [
        ./hosts/macos.nix
        ./fish.nix

        # Home Manager on macOS
        home-manager.darwinModules.home-manager
        ({ lib, zen-browser, ... }: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # Automatically backup files before home-manager overwrites them
          home-manager.backupFileExtension = "backup";
          # Pass flake inputs to home-manager modules (e.g. home.nix)
          home-manager.extraSpecialArgs = { inherit zen-browser; };
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
