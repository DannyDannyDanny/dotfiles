# Dead-man's-switch for the monitoring host (runs on vps-relay).
#
# sunken-ship's Prometheus alerts on every OTHER host going down — but if
# sunken-ship itself dies, alerting goes dark silently. This timer probes
# sunken-ship's node-exporter over ZeroTier every 2 minutes and sends a
# Telegram message (same bot + chat as alertmanager) after 3 consecutive
# failures, plus a recovery message when the probe succeeds again.
#
# Token: /etc/fleet-watchdog/telegram-token (root 0400, NOT in repo —
# same @HarakatBot token as sunken-ship's alertmanager-telegram clan var).
# Without the file the watchdog still runs and logs, but can't send.
{ pkgs, ... }:
let
  zt = import ../lib/zerotier-hosts.nix;
  probeUrl = "http://[${zt."sunken-ship"}]:9100/metrics";
  tokenFile = "/etc/fleet-watchdog/telegram-token";
  chatId = "66070351";
  failThreshold = 3;

  watchdogScript = pkgs.writeShellScript "fleet-watchdog" ''
    set -euo pipefail
    state_dir=''${STATE_DIRECTORY:-/var/lib/fleet-watchdog}
    fails_f="$state_dir/consecutive-failures"
    alerted_f="$state_dir/alerted"

    send() {
      if [ -r "${tokenFile}" ]; then
        ${pkgs.curl}/bin/curl -sf -m 10 \
          "https://api.telegram.org/bot$(cat ${tokenFile})/sendMessage" \
          --data-urlencode "chat_id=${chatId}" \
          --data-urlencode "text=$1" >/dev/null \
          || echo "telegram send failed" >&2
      else
        echo "no token at ${tokenFile}; would send: $1" >&2
      fi
    }

    fails=$(cat "$fails_f" 2>/dev/null || echo 0)
    if ${pkgs.curl}/bin/curl -sf -m 10 -o /dev/null "${probeUrl}"; then
      echo 0 > "$fails_f"
      if [ -e "$alerted_f" ]; then
        rm -f "$alerted_f"
        send "✅ sunken-ship is back — watchdog probe from vps-relay succeeded."
      fi
    else
      fails=$((fails + 1))
      echo "$fails" > "$fails_f"
      echo "probe failed ($fails consecutive)" >&2
      if [ "$fails" -ge ${toString failThreshold} ] && [ ! -e "$alerted_f" ]; then
        touch "$alerted_f"
        send "🚨 sunken-ship appears DOWN — watchdog on vps-relay failed $fails probes over ZeroTier. Prometheus alerting may be dark."
      fi
    fi
  '';
in
{
  systemd.services.fleet-watchdog = {
    description = "Probe sunken-ship (monitoring host) over ZT; Telegram on sustained failure";
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = watchdogScript;
      StateDirectory = "fleet-watchdog";
    };
  };

  systemd.timers.fleet-watchdog = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "2m";
      RandomizedDelaySec = "20s";
    };
  };
}
