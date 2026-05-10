# Prometheus + Alertmanager + Grafana on sunken-ship.
#
# Scrape targets are the clan ZeroTier IPv6s — kept in sync with
# vars/per-machine/<host>/zerotier/zerotier-ip/value.
#
# Telegram receiver uses the existing @HarakatBot. Drop the bot token at
# /etc/alertmanager/telegram-token (mode 0400, root) before rebuild — same
# manual-secret pattern as the other Telegram bots in the repo.
#
# Routing: critical alerts repeat every 1h, everything else every 4h.
{ ... }:
let
  sunkenShipZTv6 = "fdd5:53a2:de33:d269:6499:93d5:53a2:de33";
  phantomShipZTv6 = "fdd5:53a2:de33:d269:6499:936c:48a:bbdc";
  vpsRelayZTv6 = "fdd5:53a2:de33:d269:6499:9305:339f:2ed3";

  target = ip: "[${ip}]:9100";
in {
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
      static_configs = [{ targets = [ "127.0.0.1:9093" ]; }];
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
              bot_token_file = "/etc/alertmanager/telegram-token";
              chat_id = 66070351;
              api_url = "https://api.telegram.org";
              parse_mode = "";
            }];
          }
          {
            name = "telegram-critical";
            telegram_configs = [{
              bot_token_file = "/etc/alertmanager/telegram-token";
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

  services.grafana = {
    enable = true;
    settings.server = {
      http_addr = "::";
      http_port = 3000;
      domain = "sunken-ship.clan";
    };
    # Drop a random 32+ char string at /etc/grafana/secret-key (mode 0400,
    # owned by grafana:grafana) before rebuild — same manual-secret pattern
    # as /etc/alertmanager/telegram-token. Used to encrypt secrets stored
    # in Grafana's DB; nothing to rotate on a fresh install.
    settings.security.secret_key = "$__file{/etc/grafana/secret-key}";
    provision.datasources.settings.datasources = [{
      name = "Prometheus";
      type = "prometheus";
      url = "http://[::1]:9090";
      isDefault = true;
    }];
  };

  # Grafana on the ZeroTier mesh only. Prometheus + Alertmanager bind to
  # localhost so they're not reachable off-host.
  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 3000 ];
}
