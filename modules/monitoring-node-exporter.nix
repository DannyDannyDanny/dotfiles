# Prometheus node_exporter — exposes host metrics on :9100, scoped to the
# ZeroTier mesh so only sunken-ship (the Prometheus server) can scrape it.
{ ... }: {
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "[::]";
    enabledCollectors = [ "systemd" ];
  };

  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 9100 ];
}
