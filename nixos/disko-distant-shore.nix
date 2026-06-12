# Declarative disk layout for distant-shore (ThinkPad X13 Gen 2 — 256 GB
# SK Hynix NVMe). UEFI/systemd-boot, LUKS-encrypted root.
#
# Headless + unattended reboots (dm-pull-deploy) are handled by TPM2
# auto-unlock instead of a boot-time passphrase prompt:
#   - At install, disko prompts once for a LUKS passphrase (kept as the
#     recovery fallback — store it in the password manager).
#   - After first boot, enroll the TPM (binds to Secure Boot state via
#     PCR 7; shim+MOK chain is already part of this host's plan):
#       sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p2
#   - crypttabExtraOpts below makes initrd try TPM2 first, falling back
#     to the passphrase prompt if unsealing fails (e.g. firmware update
#     changed PCRs).
# Requires boot.initrd.systemd.enable = true (set in hosts/distant-shore.nix).
# Device is wiped + repartitioned at install time by clan/nixos-anywhere.
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
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings = {
                allowDiscards = true;
                crypttabExtraOpts = [ "tpm2-device=auto" ];
              };
              # No keyFile/passwordFile => interactive passphrase at install
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
  };
}
