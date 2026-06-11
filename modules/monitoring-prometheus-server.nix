# Prometheus + Alertmanager + Grafana on sunken-ship.
#
# Scrape targets are the clan ZeroTier IPv6s — kept in sync with
# vars/per-machine/<host>/zerotier/zerotier-ip/value.
#
# Secrets are declarative via clan vars (sops-backed, encrypted in-repo) —
# nothing is hand-dropped into /etc:
#   - grafana-secret-key   : random 32-byte key, auto-generated.
#   - alertmanager-telegram: @HarakatBot token, entered once at a prompt.
# Generate them before the first deploy (on a Linux box that holds the admin
# age key — same flow as the other clan vars), then commit the new vars/ +
# sops/ entries:
#     clan vars generate sunken-ship --flake ~/dotfiles
# Both are handed to their service via systemd LoadCredential, which works
# with grafana's static user and alertmanager's DynamicUser alike.
#
# The Grafana dashboard (Node Exporter Full, grafana.com #1860) is
# provisioned declaratively from ./grafana-dashboards — no UI import step.
#
# Routing: critical alerts repeat every 4h, everything else every 4h.
{ config, pkgs, ... }:
let
  # Fleet ZT IPv6 addresses — single source of truth in lib/zerotier-hosts.nix.
  zt = import ../lib/zerotier-hosts.nix;
  sunkenShipZTv6   = zt."sunken-ship";
  phantomShipZTv6  = zt."phantom-ship";
  vpsRelayZTv6     = zt."vps-relay";
  distantShoreZTv6 = zt."distant-shore";
  foreignPortZTv6  = zt."foreign-port";

  target = ip: "[${ip}]:9100";

  # The fleet, in nautical order. Used to label every scraped series with a
  # friendly `alias` (ship name) — present even when a host is down.
  fleet = [
    { name = "sunken-ship";   ip = sunkenShipZTv6; }
    { name = "phantom-ship";  ip = phantomShipZTv6; }
    { name = "vps-relay";     ip = vpsRelayZTv6; }
    { name = "distant-shore"; ip = distantShoreZTv6; }
    { name = "foreign-port";  ip = foreignPortZTv6; }
  ];

  # Telegram token, exposed to the alertmanager unit via systemd
  # LoadCredential (below) — readable only by the unit, DynamicUser and all.
  telegramTokenCred = "/run/credentials/alertmanager.service/telegram_token";
  # Random Grafana DB-encryption key, same mechanism.
  grafanaSecretKeyCred = "/run/credentials/grafana.service/secret_key";

  # Provisioned dashboards live in ./grafana-dashboards. Copy them all in;
  # only the vendored Node Exporter Full (#1860) needs its datasource
  # template-var uid "${ds_prometheus}" rewritten to our fixed "prometheus"
  # uid. The hand-authored fleet-*.json already reference uid "prometheus".
  grafanaDashboards = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p "$out"
    cp ${./grafana-dashboards}/*.json "$out"/
    chmod +w "$out"/node-exporter-full.json
    sed -i 's/''${ds_prometheus}/prometheus/g' "$out"/node-exporter-full.json
  '';
in {
  # --- Declarative secrets (clan vars → sops, encrypted in the repo) --------
  clan.core.vars.generators.grafana-secret-key = {
    files."secret_key" = { };  # secret, root:root 0400 (defaults)
    runtimeInputs = [ pkgs.coreutils ];
    script = ''
      head -c 32 /dev/urandom | base64 | tr -d '\n' > "$out"/secret_key
    '';
  };
  clan.core.vars.generators.alertmanager-telegram = {
    files."token" = { };
    prompts.token = {
      description = "Telegram bot token for @HarakatBot (alertmanager alerts)";
      type = "hidden";
      persist = true;  # store the prompt straight into files.token
    };
  };

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "[::1]";
    # Long-haul raw (30s) retention: ~1000 days (~2.7 years). At the
    # measured ~20 MB/day this plateaus near 20 GB — trivial vs free disk.
    # The retention.size backstop hard-caps the TSDB at 30 GB so a future
    # jump in series count can never run the root filesystem out of space
    # (whichever limit hits first wins). See the homelab roadmap for the
    # downsampled-multi-year tier (Thanos / VictoriaMetrics).
    retentionTime = "1000d";
    extraFlags = [ "--storage.tsdb.retention.size=30GB" ];

    globalConfig = {
      scrape_interval = "30s";
      evaluation_interval = "30s";
    };

    scrapeConfigs = [
      {
        job_name = "node";
        # One static_config per ship so every series carries a friendly
        # `alias` label (used by the fleet dashboards + alerts) — present
        # even when a host is down, unlike node_uname_info's nodename.
        static_configs = map (h: {
          targets = [ (target h.ip) ];
          labels = { job = "node"; alias = h.name; };
        }) fleet;
      }
      {
        # CrowdSec LAPI + engine Prometheus metrics — only vps-relay runs it.
        job_name = "crowdsec";
        static_configs = [{
          targets = [ "[${vpsRelayZTv6}]:6060" ];
          labels = { job = "crowdsec"; alias = "vps-relay"; };
        }];
      }
    ];

    ruleFiles = [
      (builtins.toFile "host-rules.yml" (builtins.toJSON {
        groups = [{
          name = "hosts";
          rules = [
            {
              alert = "HostDown";
              expr = ''up{job="node"} == 0'';
              for = "5m";
              labels.severity = "critical";
              annotations = {
                summary = "{{ $labels.alias }} is down";
                description = "{{ $labels.alias }} ({{ $labels.instance }}) has been unreachable for 5 minutes.";
              };
            }
            {
              # Root filesystem over 85% full. Warning (4h repeat), not
              # critical — capacity creep, not an outage.
              alert = "DiskFull";
              expr = ''100 * (1 - node_filesystem_avail_bytes{mountpoint="/",fstype="ext4"} / node_filesystem_size_bytes{mountpoint="/",fstype="ext4"}) > 85'';
              for = "15m";
              labels.severity = "warning";
              annotations = {
                summary = ''{{ $labels.alias }} root disk {{ $value | printf "%.0f" }}% full'';
                description = ''{{ $labels.alias }} "/" has been above 85% for 15 minutes.'';
              };
            }
            {
              # Any hwmon sensor sustained above 80°C.
              alert = "HighTemp";
              expr = ''max by (alias) (node_hwmon_temp_celsius) > 80'';
              for = "10m";
              labels.severity = "warning";
              annotations = {
                summary = ''{{ $labels.alias }} running hot: {{ $value | printf "%.0f" }}°C'';
                description = ''{{ $labels.alias }} hottest sensor above 80°C for 10 minutes.'';
              };
            }
          ];
        }];
      }))
    ];

    alertmanagers = [{
      static_configs = [{ targets = [ "[::1]:9093" ]; }];
    }];

    alertmanager = {
      enable = true;
      port = 9093;
      listenAddress = "[::1]";
      configuration = {
        route = {
          receiver = "telegram-default";
          group_by = [ "alertname" ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
          routes = [{
            matchers = [ ''severity="critical"'' ];
            receiver = "telegram-critical";
            group_wait = "10s";
            group_interval = "5m";
            repeat_interval = "4h";
          }];
        };
        receivers = [
          {
            name = "telegram-default";
            telegram_configs = [{
              bot_token_file = telegramTokenCred;
              chat_id = 66070351;
              api_url = "https://api.telegram.org";
              parse_mode = "";
            }];
          }
          {
            name = "telegram-critical";
            telegram_configs = [{
              bot_token_file = telegramTokenCred;
              chat_id = 66070351;
              api_url = "https://api.telegram.org";
              parse_mode = "";
              message = ''
                CRITICAL: {{ .CommonLabels.alertname }}
                {{ range .Alerts }}{{ .Annotations.summary }}
                {{ .Annotations.description }}
                {{ end }}'';
            }];
          }
        ];
      };
    };
  };

  # Hand the Telegram token to alertmanager as a systemd credential. The
  # clan var is decrypted to a root-only path; LoadCredential re-exposes it
  # to the (DynamicUser) unit under $CREDENTIALS_DIRECTORY.
  systemd.services.alertmanager.serviceConfig.LoadCredential =
    [ "telegram_token:${config.clan.core.vars.generators.alertmanager-telegram.files."token".path}" ];

  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "::";
      http_port = 3000;
      # Served publicly via vps-relay Caddy (grafana.dannydannydanny.me),
      # behind a basic_auth gate. root_url keeps Grafana's redirects/links
      # correct behind the proxy. Still reachable ZT-direct on :3000 too.
      domain = "grafana.dannydannydanny.me";
      root_url = "https://grafana.dannydannydanny.me/";
    };
    # Encrypts secrets stored in Grafana's DB. Sourced from a clan var via
    # systemd LoadCredential (see below) instead of a hand-placed /etc file.
    settings.security.secret_key = "$__file{${grafanaSecretKeyCred}}";
    provision.datasources.settings = {
      # The earlier uid-less provisioning left a "Prometheus" datasource with
      # a random uid in Grafana's DB. Now that the dashboard pins datasource
      # uid "prometheus", delete the stale one first so the fixed-uid
      # datasource provisions cleanly — otherwise Grafana 13 aborts startup
      # with "Datasource provisioning error: data source not found".
      deleteDatasources = [{ name = "Prometheus"; orgId = 1; }];
      datasources = [{
        name = "Prometheus";
        type = "prometheus";
        uid = "prometheus";  # referenced by the provisioned dashboard
        url = "http://[::1]:9090";
        isDefault = true;
      }];
    };
    # Node Exporter Full (#1860) — CPU/RAM/disk/net/uptime/processes per host.
    provision.dashboards.settings.providers = [{
      name = "default";
      options.path = grafanaDashboards;
    }];
  };
  systemd.services.grafana.serviceConfig.LoadCredential =
    [ "secret_key:${config.clan.core.vars.generators.grafana-secret-key.files."secret_key".path}" ];

  # Grafana on the ZeroTier mesh only. Prometheus + Alertmanager bind to
  # localhost so they're not reachable off-host.
  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 3000 ];
}
