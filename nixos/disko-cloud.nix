# Disko layout for cloud VPS installs (e.g. Hetzner Cloud).
# GPT with a 1MB BIOS boot partition (for GRUB on a BIOS system) + root.
# No LUKS — the provider has physical disk access anyway and there's
# no operator present at boot to enter a passphrase.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          # GRUB BIOS boot partition — holds stage-1.5 bootloader code.
          # Type EF02. No filesystem.
          BIOSBOOT = {
            size = "1M";
            type = "EF02";
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
