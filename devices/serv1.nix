{ config, pkgs, ... }:

let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
in
{

  imports = [
    (import ../default.nix { inherit config pkgs username; })
    ../linux/features/docker.nix
    ../linux/filesystem/nas/mount.nix
    ../linux/vpn.nix
  ];

  environment.systemPackages = [
    pkgs.unixODBC
    pkgs.unixODBCDrivers.msodbcsql17
    pkgs.plantuml
  ];
  
  environment.unixODBCDrivers = [
    pkgs.unixODBCDrivers.msodbcsql17
  ];

  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;


}
