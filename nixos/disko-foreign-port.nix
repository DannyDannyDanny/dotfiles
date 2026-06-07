# Declarative disk layout for distant-shore. UEFI/systemd-boot, no
# encryption: it's a headless, WiFi-only server that must reboot
# unattended (clan dm-pull-deploy), so a LUKS passphrase prompt at boot
# would hang it. Mirrors sunken-ship's plain-ext4 choice. Device is wiped
# + repartitioned at install time by clan/nixos-anywhere.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0022" "dmask=0022" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
