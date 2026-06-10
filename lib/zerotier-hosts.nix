# Single source of truth for the fleet's ZeroTier IPv6 addresses.
#
# Clan publishes these as generated vars at
# vars/per-machine/<host>/zerotier/zerotier-ip/value; they are duplicated
# here — in this one place only — so modules can use them at eval time.
# Consumers: flake-modules/clan.nix, modules/monitoring-prometheus-server.nix,
# nixos/home/danny/home.nix, nixos/hosts/vps-relay.nix.
{
  sunken-ship = "fdd5:53a2:de33:d269:6499:93d5:53a2:de33";
  phantom-ship = "fdd5:53a2:de33:d269:6499:936c:48a:bbdc";
  vps-relay = "fdd5:53a2:de33:d269:6499:9305:339f:2ed3";
  distant-shore = "fdd5:53a2:de33:d269:6499:93b6:ef1a:c3b3";
  foreign-port = "fdd5:53a2:de33:d269:6499:9389:9b18:6c52";
}
