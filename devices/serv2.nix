{ config, pkgs, ... }:


{

  imports = [
    ../common.nix
    ../system/features/docker.nix
    ../system/filesystem/nas/mount.nix
  ];


  networking.hostName = "serv2";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
