{...}: {
  services.zfs.autoScrub.enable = true;

  imports = [
    ./root.nix
    #./tank.nix
    ./sanoid.nix
  ];

  boot.zfs.extraPools = ["tank"];

  # Import rpool without -f, so ZFS's "in use by another host" check applies.
  # Safe here: networking.hostId is fixed. If a boot ever fails on it, add
  # zfs_force=1 to the kernel params from the bootloader once.
  boot.zfs.forceImportRoot = false;
}
