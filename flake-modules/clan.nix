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

    # Direct SSH reachability on the LAN. Priority 2000 > ZT's 900, so
    # `clan machines update` prefers LAN hostnames over ZT IPv6 — and uses
    # the right user (ZT service defaults to root@).
    inventory.instances.internet = {
      module.name = "internet";
      module.input = "clan-core";
      roles.default.machines.sunken-ship.settings = {
        host = "sunken-ship";
        user = "danny";
      };
      roles.default.machines.phantom-ship.settings = {
        host = "phantom-ship";
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
          clan.core.networking.targetHost = "danny@sunken-ship";
          clan.core.networking.buildHost = "danny@sunken-ship";
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
          clan.core.networking.targetHost = "danny@phantom-ship";
          clan.core.networking.buildHost = "danny@phantom-ship";
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
