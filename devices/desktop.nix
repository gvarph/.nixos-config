{ config, lib, pkgs, username, ... }:

let
  username = "gvarph";
in
{

  imports = [
    (import ../common.nix
      { inherit config pkgs username; })
    ../system/features/docker.nix
    # TODO:  ../system/filesystem/nas/mount.nix
    #../hypr/enable.nix
    (import ../home/ui { inherit config pkgs username; })

  ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
  };

  networking.hostName = "deskt";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


}
