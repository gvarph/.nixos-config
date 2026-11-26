# Hibernation, resuming from either a swapfile or a LUKS swap partition.
# Pass exactly one of:
#
# swapfile = { sizeGiB; resumeDevice; resumeOffset ? null; path ? "/var/lib/swapfile"; }
#   resumeDevice: the filesystem holding the swapfile (by-uuid of the fs, or the
#     /dev/mapper device when root is LUKS).
#   resumeOffset: first physical_offset from `sudo filefrag -v <path>`. Only known
#     after the swapfile exists, so the first deploy goes without it (swap works,
#     resume doesn't); the offset changes if the file is recreated.
#
# luksPartitionUuid = "<uuid of the crypto_LUKS partition>";
#   Unlocked in the initrd (TPM2 if enrolled, else passphrase) so systemd can
#   resume from it before root is mounted. Enroll the TPM once with
#   `sudo systemd-cryptenroll --tpm2-device=auto /dev/disk/by-uuid/<uuid>`.
{
  swapfile ? null,
  luksPartitionUuid ? null,
}:
assert (swapfile == null) != (luksPartitionUuid == null);
  {lib, ...}:
    if swapfile != null
    then {
      swapDevices = [
        {
          device = swapfile.path or "/var/lib/swapfile";
          size = swapfile.sizeGiB * 1024;
        }
      ];
      boot.resumeDevice = swapfile.resumeDevice;
      boot.kernelParams = lib.optional ((swapfile.resumeOffset or null) != null) "resume_offset=${toString swapfile.resumeOffset}";
    }
    else let
      name = "luks-${luksPartitionUuid}";
      mapped = "/dev/mapper/${name}";
    in {
      boot.initrd.luks.devices.${name} = {
        device = "/dev/disk/by-uuid/${luksPartitionUuid}";
        crypttabExtraOpts = ["tpm2-device=auto"];
      };
      swapDevices = [{device = mapped;}];
      boot.resumeDevice = mapped;
    }
