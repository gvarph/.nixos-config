{ config, lib, pkgs, ... }:


{

  imports = [
    ../common.nix
    ../system/features/docker.nix
    # TODO:  ../system/filesystem/nas/mount.nix
    ../hypr/enable.nix
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
