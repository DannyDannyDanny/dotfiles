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

    # Inventory machines — required for `inventory.instances` role bindings
    # to resolve. Host-specific NixOS config lives under `machines.<name>`
    # below.
    inventory.machines.sunken-ship = { };
    inventory.machines.phantom-ship = { };

    # ZeroTier mesh VPN. sunken-ship is the controller (manages network
    # membership); phantom-ship is a peer. The mac joins manually as an
    # external ZT client and is authorized on the controller by node ID.
    inventory.instances.zerotier = {
      module.name = "zerotier";
      module.input = "clan-core";
      roles.controller.machines.sunken-ship = { };
      roles.peer.machines.phantom-ship = { };
      roles.peer.machines.sunken-ship = { };
    };

    # `clan machines update` connection target. Priority 2000 > ZT's 900
    # and overrides the ZT service's root@ default. Using the ZT IPv6 as
    # the host makes updates work regardless of LAN DNS / mDNS state.
    inventory.instances.internet = {
      module.name = "internet";
      module.input = "clan-core";
      roles.default.machines.sunken-ship.settings = {
        host = "fdd5:53a2:de33:d269:6499:93d5:53a2:de33";
        user = "danny";
      };
      roles.default.machines.phantom-ship.settings = {
        host = "fdd5:53a2:de33:d269:6499:936c:48a:bbdc";
        user = "danny";
      };
    };

    # Preserve current network / init stack (no systemd-networkd/resolved,
    # no boot.initrd.systemd, no extra debug packages). Revisit per-service
    # in later stages rather than flipping this fleet-wide.
    machines.sunken-ship = {
      imports = [
        {
          clan.core.enableRecommendedDefaults = false;
          clan.core.networking.targetHost = "danny@[fdd5:53a2:de33:d269:6499:93d5:53a2:de33]";
          clan.core.networking.buildHost = "danny@[fdd5:53a2:de33:d269:6499:93d5:53a2:de33]";
        }
        ../nixos/hosts/sunken-ship.nix
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
        {
          clan.core.enableRecommendedDefaults = false;
          clan.core.networking.targetHost = "danny@[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]";
          clan.core.networking.buildHost = "danny@[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]";
        }
        inputs.nix-openclaw.nixosModules.openclaw-gateway
        ../nixos/hosts/phantom-ship.nix
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
