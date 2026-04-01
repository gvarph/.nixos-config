{
  config,
  pkgs,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    #./hardware-configuration.nix
    ./disko
    ./nginx.nix

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
  networking.hostId = "f531fbde"; # 8 hex characters, stable

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
  ];

  boot.kernelParams = [
  ];

  powerManagement.powertop.enable = true;
  boot.supportedFilesystems = ["zfs"];

  nixpkgs.hostPlatform = "x86_64-linux";
}
