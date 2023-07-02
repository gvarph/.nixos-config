{ config, pkgs, ... }:


{

  imports = [
    ../common.nix
    ../system/docker.nix
  ];


  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
