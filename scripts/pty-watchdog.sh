#!/usr/bin/env bash
# Warn before the pseudo-terminal pool runs dry.
# The Claude desktop app leaks PTY masters (visible via `lsof /dev/ptmx`); once
# the pool hits kern.tty.ptmx_max, anything calling forkpty fails with
# "Device not configured". Quitting and reopening Claude releases the masters.
# Threshold is 80% of the *current* max: the cap is 999 while the sysctl
# band-aid holds, but resets to 511 on reboot — a fixed number would miss that.

set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

max="$(/usr/sbin/sysctl -n kern.tty.ptmx_max)"
used="$(find /dev -maxdepth 1 -name 'ttys*' | wc -l | tr -d ' ')"
threshold="${PTY_WATCHDOG_THRESHOLD:-$(( max * 80 / 100 ))}"

(( used > threshold )) || exit 0

# Nag at most once per hour.
STAMP="${TMPDIR:-/tmp}/pty-watchdog.last-notified"
now="$(date +%s)"
if [[ -f "$STAMP" ]] && (( now - $(<"$STAMP") < 3600 )); then
  exit 0
fi
printf '%s' "$now" >"$STAMP"

claude="$(lsof /dev/ptmx 2>/dev/null | grep -c Claude || true)"

echo "$(date '+%F %T') used=${used}/${max} claude=${claude} — notifying"
/usr/bin/osascript -e "display notification \"${used}/${max} PTYs allocated (Claude holds ${claude}). Quit and reopen Claude to release them.\" with title \"pty-watchdog\""
