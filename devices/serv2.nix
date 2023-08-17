{ config, pkgs, ... }:


{

  imports = [
    ../common.nix
    ../linux/features/docker.nix
    ../linux/filesystem/nas/mount.nix
  ];


  networking.hostName = "serv2";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
