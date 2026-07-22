{...}: {
  services.zfs.autoScrub.enable = true;

  imports = [
    ./root.nix
    #./tank.nix
    ./sanoid.nix
  ];

  boot.zfs.extraPools = ["tank"];
}
