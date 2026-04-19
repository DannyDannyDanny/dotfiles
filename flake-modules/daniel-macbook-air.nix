{ inputs, ... }: {
  flake.darwinConfigurations."Daniel-Macbook-Air" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      # Overlay: make zen-browser available as pkgs.zen-browser
      { nixpkgs.overlays = [ (final: prev: {
          zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
        }) ];
      }

      ../nixos/hosts/daniel-macbook-air.nix
      ../nixos/fish.nix

      inputs.home-manager.darwinModules.home-manager
      (import ../lib/home-manager-user.nix {
        lib = inputs.nixpkgs.lib;
        user = "danny";
        homeDirectory = "/Users/danny";
        userImports = [ ../nixos/home/danny/home.nix ];
      })
    ];
  };
}
