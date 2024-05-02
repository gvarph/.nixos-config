{
  config,
  pkgs,
  ...
}: let
  username = "gvarph";
  #gpuId = "10de:1f02";
  #soundId = "10de:10f9";
in {
  imports = [
    (import ../default.nix {inherit config pkgs username;})
    ../linux/features/docker.nix
    ../linux/filesystem/nas/mount.nix
  ];

  networking.hostName = "serv2";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
