# clan.lol wiring for the homelab.
#
# Declares `sunken-ship` and `phantom-ship` as clan machines. Each machine's
# `imports` list is the NixOS module set that used to live in its own
# flake-module. clan-core produces `flake.nixosConfigurations.<name>` from
# these, which is why the old per-host flake-modules were removed.
#
# The mac stays outside the clan — admin only, uses `clan machines update`
# to push to the servers.
{ config, inputs, ... }:
let
  lib = inputs.nixpkgs.lib;
  hmModule = { user, homeDirectory, stateVersion ? null, userImports ? [ ] }:
    import ../lib/home-manager-user.nix {
      inherit lib user homeDirectory stateVersion userImports;
    };
in {
  imports = [ inputs.clan-core.flakeModules.default ];

  clan = {
    meta.name = "homelab";

    # Preserve current network / init stack (no systemd-networkd/resolved,
    # no boot.initrd.systemd, no extra debug packages). Revisit per-service
    # in later stages rather than flipping this fleet-wide.
    machines.sunken-ship = {
      imports = [
        { clan.core.enableRecommendedDefaults = false; }
        ../hosts/sunken-ship.nix
        config.flake.nixosModules.dotfiles-rebuild
        inputs.home-manager.nixosModules.home-manager
        (hmModule {
          user = "danny";
          homeDirectory = "/home/danny";
          stateVersion = "25.11";
        })
      ];
    };

    machines.phantom-ship = {
      imports = [
        { clan.core.enableRecommendedDefaults = false; }
        inputs.nix-openclaw.nixosModules.openclaw-gateway
        ../hosts/phantom-ship.nix
        config.flake.nixosModules.dotfiles-rebuild
        inputs.home-manager.nixosModules.home-manager
        (hmModule {
          user = "danny";
          homeDirectory = "/home/danny";
          stateVersion = "25.11";
        })
      ];
    };
  };
}
