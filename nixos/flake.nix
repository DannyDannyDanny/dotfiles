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

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    vscode-server,
    nix-darwin,
    self,
    home-manager,
    zen-browser,
    disko,
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
          ./fish.nix

          # Home Manager on WSL
          home-manager.nixosModules.home-manager
          ({ lib, ... }: {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.users.dth = { ... }: {
              home.username = "dth";
              home.homeDirectory = lib.mkForce "/home/dth";
              imports = [ ./home/danny/home.nix ];
            };
          })
        ];
      };

      sunken-ship = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/sunken-ship.nix

          # Home Manager on NixOS
          home-manager.nixosModules.home-manager
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

      # For disko-install: LUKS + WiFi; hostname/WiFi via --system-config.
      server-install = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./disko-server.nix
          ./hosts/server-install.nix
        ];
      };

      # Custom minimal installer ISO (build with: nix build .#installer-iso).
      # Optional: add ./installer-wifi.nix (gitignored) to modules for live WiFi.
      installer-iso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./installer-iso.nix ];
      };
    };

    packages.x86_64-linux.installer-iso =
      self.nixosConfigurations.installer-iso.config.system.build.isoImage;

    # macOS (nix-darwin) configuration
    darwinConfigurations."Daniel-Macbook-Air" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit zen-browser; };
      modules = [
        ./hosts/daniel-macbook-air.nix
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
            imports = [
              ./home/danny/home.nix
            ];
          };
        })
      ];
    };
  };
}
