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
  # NOTE on stateVersion: the HM stateVersion ("25.11" below) records when
  # home-manager was FIRST ACTIVATED for this user (clan bootstrap, Apr 2026)
  # and intentionally differs from the older system.stateVersion of the
  # ships ("24.11", OS install era). Neither should be bumped or "aligned" —
  # both gate one-time migration defaults, not features.
  hmModule = { user, homeDirectory, stateVersion ? null, userImports ? [ ] }:
    import ../lib/home-manager-user.nix {
      inherit lib user homeDirectory stateVersion userImports;
    };

  # Fleet ZT IPv6 addresses — single source of truth in lib/zerotier-hosts.nix.
  zt = import ../lib/zerotier-hosts.nix;
  sunkenShipZTv6 = zt."sunken-ship";
  phantomShipZTv6 = zt."phantom-ship";
  vpsRelayZTv6 = zt."vps-relay";
  distantShoreZTv6 = zt."distant-shore";
  foreignPortZTv6 = zt."foreign-port";

  # Shared across both servers: /etc/hosts entries so data-mesher's
  # libp2p /dns/<machine>.clan/... bootstrap multiaddrs resolve over ZT.
  clanHostsModule = {
    networking.hosts = {
      "${sunkenShipZTv6}" = [ "sunken-ship.clan" ];
      "${phantomShipZTv6}" = [ "phantom-ship.clan" ];
      "${vpsRelayZTv6}" = [ "vps-relay.clan" ];
      "${distantShoreZTv6}" = [ "distant-shore.clan" ];
      "${foreignPortZTv6}" = [ "foreign-port.clan" ];
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
    inventory.machines.distant-shore = { };
    inventory.machines.foreign-port = { };

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
      roles.peer.machines.distant-shore = { };
      roles.peer.machines.foreign-port = { };
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
      roles.default.machines.distant-shore = { };
      roles.default.machines.foreign-port = { };
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
      roles.default.machines.distant-shore.settings.action = "switch";
      roles.default.machines.foreign-port.settings.action = "switch";
    };

    # `clan machines update` connection target. Priority 2000 > ZT's 900
    # and overrides the ZT service's root@ default. Using the ZT IPv6 as
    # the host makes updates work regardless of LAN DNS / mDNS state.
    inventory.instances.internet = {
      module.name = "internet";
      module.input = "clan-core";
      roles.default.machines.sunken-ship.settings = {
        host = sunkenShipZTv6;
        user = "danny";
      };
      roles.default.machines.phantom-ship.settings = {
        host = phantomShipZTv6;
        user = "danny";
      };
      roles.default.machines.vps-relay.settings = {
        host = vpsRelayZTv6;
        user = "danny";
      };
      roles.default.machines.distant-shore.settings = {
        host = distantShoreZTv6;
        user = "danny";
      };
      roles.default.machines.foreign-port.settings = {
        host = foreignPortZTv6;
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
          clan.core.networking.targetHost = "danny@[${sunkenShipZTv6}]";
          clan.core.networking.buildHost = "danny@[${sunkenShipZTv6}]";
        }
        clanHostsModule
        ../nixos/hosts/sunken-ship.nix
        config.flake.nixosModules.server-debug-tools
        config.flake.nixosModules.monitoring-node-exporter
        config.flake.nixosModules.monitoring-prometheus-server
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
        }
        clanHostsModule
        ../nixos/hosts/vps-relay.nix
        config.flake.nixosModules.monitoring-node-exporter
        inputs.home-manager.nixosModules.home-manager
        (hmModule {
          user = "danny";
          homeDirectory = "/home/danny";
          stateVersion = "25.11";
        })
      ];
    };

    # distant-shore — ThinkPad X13 Gen 2, WiFi, Secure Boot via shim+MOK.
    # buildHost = sunken-ship: x86_64 builder whose key is already in
    # distant-shore's authorized_keys, avoiding fragile self-SSH for closures.
    machines.distant-shore = {
      imports = [
        {
          clan.core.enableRecommendedDefaults = false;
          clan.core.networking.targetHost = "danny@[${distantShoreZTv6}]";
          clan.core.networking.buildHost = "danny@[${sunkenShipZTv6}]";
        }
        clanHostsModule
        ../nixos/hosts/distant-shore.nix
        config.flake.nixosModules.monitoring-node-exporter
        inputs.home-manager.nixosModules.home-manager
        (hmModule {
          user = "danny";
          homeDirectory = "/home/danny";
          stateVersion = "25.11";
        })
      ];
    };

    # foreign-port — WiFi-only laptop server, locally-signed boot chain.
    # buildHost = sunken-ship to avoid self-SSH for closure copy.
    machines.foreign-port = {
      imports = [
        {
          clan.core.enableRecommendedDefaults = false;
          clan.core.networking.targetHost = "danny@[${foreignPortZTv6}]";
          clan.core.networking.buildHost = "danny@[${sunkenShipZTv6}]";
        }
        clanHostsModule
        ../nixos/hosts/foreign-port.nix
        config.flake.nixosModules.monitoring-node-exporter
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
          clan.core.networking.targetHost = "danny@[${phantomShipZTv6}]";
          clan.core.networking.buildHost = "danny@[${phantomShipZTv6}]";
        }
        clanHostsModule
        inputs.nix-openclaw.nixosModules.openclaw-gateway
        ../nixos/hosts/phantom-ship.nix
        config.flake.nixosModules.server-debug-tools
        config.flake.nixosModules.monitoring-node-exporter
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
