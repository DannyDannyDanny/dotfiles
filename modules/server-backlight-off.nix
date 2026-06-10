# Headless servers with a built-in panel: blank the TTY and kill the
# backlight after boot to reduce burn-in. consoleblank only blanks the
# framebuffer; the backlight stays lit without the explicit write to
# /sys/class/backlight.
#
# At the console, run: brightnessctl set 100%  (or `brightnessctl max`)
# to restore brightness.
{ pkgs, ... }:

{
  boot.kernelParams = [ "consoleblank=60" ];  # blank TTY after 60s

  systemd.services.server-backlight-off = {
    description = "Turn off panel backlight after console idle (reduce burn-in)";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/sleep 65
      for d in /sys/class/backlight/*; do
        [ -f "$d/brightness" ] && echo 0 > "$d/brightness" 2>/dev/null || true
      done
    '';
  };
}
