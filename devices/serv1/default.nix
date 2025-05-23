{
  config,
  pkgs,
  pkgs-stable,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix {inherit config pkgs pkgs-stable inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../secrets/age.nix
  ];

  environment.systemPackages = [
    pkgs.unixODBC
    pkgs.unixODBCDrivers.msodbcsql17
    pkgs.unixODBCDrivers.msodbcsql18
    pkgs.xdummy
  ];

  environment.unixODBCDrivers = [
    pkgs.unixODBCDrivers.msodbcsql17
    pkgs.unixODBCDrivers.msodbcsql18
  ];

  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 1194 1195];
    allowedUDPPortRanges = [
      {
        from = 4000;
        to = 4007;
      }
      {
        from = 8000;
        to = 8010;
      }
    ];
  };
  services.xserver = {
    enable = false;
    displayManager.lightdm.enable = false;
  };
}
