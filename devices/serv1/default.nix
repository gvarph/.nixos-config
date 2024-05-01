{ config, pkgs, inputs, ... }:

let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
in
{

  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix { inherit config pkgs username; })
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../linux/vpn.nix
  ];

  environment.systemPackages = [
    pkgs.unixODBC
    pkgs.unixODBCDrivers.msodbcsql17
    pkgs.plantuml
    pkgs.icu
    pkgs.dotnet-sdk_8
    pkgs.azure-cli

  ];

  environment.unixODBCDrivers = [
    pkgs.unixODBCDrivers.msodbcsql17
  ];

  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPortRanges = [

      { from = 4000; to = 4007; }
      { from = 8000; to = 8010; }
    ];
  };

}
