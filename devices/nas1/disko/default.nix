{
  pkgs,
  custom,
  ...
}: {
  services.zfs.autoScrub.enable = true;

  imports = [
    ./root.nix
    ./tank.nix
  ];
}
