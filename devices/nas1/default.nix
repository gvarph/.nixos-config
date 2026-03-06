{
  config,
  pkgs,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../secrets/age.nix
    ../../modules/nix-maintenance.nix
    ../../modules/boot-systemd.nix
    #../../linux/features/kubernetes.nix
  ];

  networking.hostName = "nas1";
  networking.networkmanager.enable = true;
}
