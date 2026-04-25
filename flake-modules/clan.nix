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

  # ZT IPv6 addresses of the two clan machines. Clan publishes these as
  # generated vars at vars/per-machine/<host>/zerotier/zerotier-ip/value;
  # duplicated here so we can drop them into /etc/hosts at module-eval time.
  sunkenShipZTv6 = "fdd5:53a2:de33:d269:6499:93d5:53a2:de33";
  phantomShipZTv6 = "fdd5:53a2:de33:d269:6499:936c:48a:bbdc";
  vpsRelayZTv6 = "fdd5:53a2:de33:d269:6499:9305:339f:2ed3";

  # Shared across both servers: /etc/hosts entries so data-mesher's
  # libp2p /dns/<machine>.clan/... bootstrap multiaddrs resolve over ZT.
  clanHostsModule = {
    networking.hosts = {
      "${sunkenShipZTv6}" = [ "sunken-ship.clan" ];
      "${phantomShipZTv6}" = [ "phantom-ship.clan" ];
      "${vpsRelayZTv6}" = [ "vps-relay.clan" ];
    };
  };
in {
  imports = [ inputs.clan-core.flakeModules.default ];

  clan = {
    meta.name = "homelab";
    # data-mesher uses `<machine>.${domain}` as a libp2p /dns/ multiaddr.
    # We don't run a DNS server for "clan" — per-machine networking.hosts
    # entries (via clanHostsModule) resolve it to the host's ZT IPv6.
    meta.domain = "clan";

    # Inventory machines — required for `inventory.instances` role bindings
    # to resolve. Host-specific NixOS config lives under `machines.<name>`
    # below.
    inventory.machines.sunken-ship = { };
    inventory.machines.phantom-ship = { };
    inventory.machines.vps-relay = { };

    # ZeroTier mesh VPN. sunken-ship is the controller (manages network
    # membership); phantom-ship is a peer. The mac joins manually as an
    # external ZT client and is authorized on the controller by node ID.
    inventory.instances.zerotier = {
      module.name = "zerotier";
      module.input = "clan-core";
      roles.controller.machines.sunken-ship = { };
      roles.peer.machines.phantom-ship = { };
      roles.peer.machines.sunken-ship = { };
      roles.peer.machines.vps-relay = { };
    };

    # data-mesher — signed-file gossip protocol over libp2p (port 7946).
    # Underpins dm-pull-deploy below. Files are registered + their allowed
    # signers managed automatically via clan service exports.
    # sunken-ship is the bootstrap node; phantom-ship joins via its
    # /dns/sunken-ship.clan/... multiaddr (resolved via /etc/hosts).
    inventory.instances.data-mesher = {
      module.name = "data-mesher";
      module.input = "clan-core";
      roles.default.machines.sunken-ship = { };
      roles.default.machines.phantom-ship = { };
      roles.bootstrap.machines.sunken-ship = { };
    };

    # dm-pull-deploy — pull-based NixOS deploy via data-mesher gossip.
    # Our clan-community input is pinned to the branch that sanitizes
    # machine.name for the status file name (upstream PR pending).
    # sunken-ship is the push node; both servers run the default watcher
    # with action="switch".
    inventory.instances.dm-pull-deploy = {
      module.name = "dm-pull-deploy";
      module.input = "clan-community";
      roles.push.machines.sunken-ship.settings = {
        gitUrl = "https://github.com/DannyDannyDanny/dotfiles.git";
        branch = "main";
      };
      roles.default.machines.sunken-ship.settings.action = "switch";
      roles.default.machines.phantom-ship.settings.action = "switch";
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
      # Using public IPv4 while ZT identity is being bootstrapped on the
      # VPS. Swap to ZT IPv6 (fdd5:53a2:de33:d269:6499:9305:339f:2ed3)
      # after the first clan update uploads SOPS keys and zerotierone
      # restarts with the clan-managed identity.
      roles.default.machines.vps-relay.settings = {
        host = "89.167.39.251";
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
        clanHostsModule
        ../nixos/hosts/sunken-ship.nix
        config.flake.nixosModules.dotfiles-rebuild
        config.flake.nixosModules.server-debug-tools
        inputs.home-manager.nixosModules.home-manager
        (hmModule {
          user = "danny";
          homeDirectory = "/home/danny";
          stateVersion = "25.11";
        })
      ];
    };

    machines.vps-relay = {
      imports = [
        {
          clan.core.enableRecommendedDefaults = false;
          # Initial install uses --target-host override; subsequent
          # updates go over ZT IPv6 (set once generated, via the
          # internet instance above).
        }
        clanHostsModule
        ../nixos/hosts/vps-relay.nix
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
        clanHostsModule
        inputs.nix-openclaw.nixosModules.openclaw-gateway
        ../nixos/hosts/phantom-ship.nix
        config.flake.nixosModules.dotfiles-rebuild
        config.flake.nixosModules.server-debug-tools
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
