# Shared home-manager wiring for NixOS and nix-darwin hosts.
#
# Usage (from a flake-module):
#   modules = [
#     inputs.home-manager.nixosModules.home-manager   # or .darwinModules
#     (import ../lib/home-manager-user.nix {
#       lib = inputs.nixpkgs.lib;
#       user = "danny";
#       homeDirectory = "/home/danny";
#       stateVersion = "25.11";        # optional
#       userImports = [ ../home/danny/home.nix ]; # optional
#     })
#   ];
{ lib
, user
, homeDirectory
, stateVersion ? null
, userImports ? [ ]
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  # Automatically back up files before home-manager overwrites them.
  home-manager.backupFileExtension = "backup";
  home-manager.users.${user} = { ... }: {
    imports = userImports;
    home = {
      username = user;
      # Force an absolute path even if another module sets a bad value.
      homeDirectory = lib.mkForce homeDirectory;
    } // lib.optionalAttrs (stateVersion != null) {
      stateVersion = stateVersion;
    };
  };
}
