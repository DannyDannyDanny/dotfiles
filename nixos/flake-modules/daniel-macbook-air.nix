{ inputs, ... }: {
  flake.darwinConfigurations."Daniel-Macbook-Air" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      # Overlay: make zen-browser available as pkgs.zen-browser
      { nixpkgs.overlays = [ (final: prev: {
          zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
        }) ];
      }

      ../hosts/daniel-macbook-air.nix
      ../fish.nix

      # Home Manager on macOS
      inputs.home-manager.darwinModules.home-manager
      ({ lib, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Automatically backup files before home-manager overwrites them
        home-manager.backupFileExtension = "backup";
        home-manager.users.danny = { ... }: {
          # Force an absolute path even if another module sets a bad value.
          home.username = "danny";
          home.homeDirectory = lib.mkForce "/Users/danny";
          imports = [
            ../home/danny/home.nix
          ];
        };
      })
    ];
  };
}
