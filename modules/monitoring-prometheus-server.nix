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
# Routing: critical alerts repeat every 1h, everything else every 4h.
{ config, pkgs, ... }:
let
  sunkenShipZTv6   = "fdd5:53a2:de33:d269:6499:93d5:53a2:de33";
  phantomShipZTv6  = "fdd5:53a2:de33:d269:6499:936c:48a:bbdc";
  vpsRelayZTv6     = "fdd5:53a2:de33:d269:6499:9305:339f:2ed3";
  distantShoreZTv6 = "fdd5:53a2:de33:d269:6499:93b6:ef1a:c3b3";
  foreignPortZTv6  = "fdd5:53a2:de33:d269:6499:9389:9b18:6c52";

  target = ip: "[${ip}]:9100";

  # Telegram token, exposed to the alertmanager unit via systemd
  # LoadCredential (below) — readable only by the unit, DynamicUser and all.
  telegramTokenCred = "/run/credentials/alertmanager.service/telegram_token";
  # Random Grafana DB-encryption key, same mechanism.
  grafanaSecretKeyCred = "/run/credentials/grafana.service/secret_key";

  # Node Exporter Full (grafana.com #1860), vendored verbatim. Its panels
  # bind the datasource to the template-var uid "${ds_prometheus}"; rewrite
  # that to our fixed Prometheus datasource uid so the dashboard renders
  # without a manual datasource pick on first open.
  grafanaDashboards = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p "$out"
    sed 's/''${ds_prometheus}/prometheus/g' \
      ${./grafana-dashboards/node-exporter-full.json} > "$out"/node-exporter-full.json
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

    globalConfig = {
      scrape_interval = "30s";
      evaluation_interval = "30s";
    };

    scrapeConfigs = [{
      job_name = "node";
      static_configs = [{
        targets = [
          (target sunkenShipZTv6)
          (target phantomShipZTv6)
          (target vpsRelayZTv6)
          (target distantShoreZTv6)
          (target foreignPortZTv6)
        ];
        labels.job = "node";
      }];
    }];

    ruleFiles = [
      (builtins.toFile "host-rules.yml" (builtins.toJSON {
        groups = [{
          name = "hosts";
          rules = [{
            alert = "HostDown";
            expr = ''up{job="node"} == 0'';
            for = "5m";
            labels.severity = "critical";
            annotations = {
              summary = "{{ $labels.instance }} is down";
              description = "{{ $labels.instance }} has been unreachable for 5 minutes.";
            };
          }];
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
            group_interval = "1m";
            repeat_interval = "1h";
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
      domain = "sunken-ship.clan";
    };
    # Encrypts secrets stored in Grafana's DB. Sourced from a clan var via
    # systemd LoadCredential (see below) instead of a hand-placed /etc file.
    settings.security.secret_key = "$__file{${grafanaSecretKeyCred}}";
    provision.datasources.settings.datasources = [{
      name = "Prometheus";
      type = "prometheus";
      uid = "prometheus";  # referenced by the provisioned dashboard
      url = "http://[::1]:9090";
      isDefault = true;
    }];
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
