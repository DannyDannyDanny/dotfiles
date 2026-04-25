# A small set of network/process debugging tools that we'd otherwise
# pick up from `clan.core.enableRecommendedDefaults = true`. The full
# clan defaults also flip systemd-networkd / systemd-resolved on, which
# breaks dnsmasq + navidrome's resolv.conf bind-mount, so we opted out
# fleet-wide and added just the useful packages explicitly here.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    htop       # process monitor
    tcpdump    # packet capture
    dnsutils   # dig, nslookup, host
    jq         # JSON parser
    curl       # HTTP client
  ];
}
