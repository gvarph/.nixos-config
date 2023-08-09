{ config, pkgs, ... }:

let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
in
{

  imports = [
    (import ../common.nix { inherit config pkgs username; })
    ../system/features/docker.nix
    ../system/filesystem/nas/mount.nix
  ];


  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

}
