{
  config,
  pkgs,
  pkgs-stable,
  inputs,
  ...
}: let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
  #az-cli-with-extensions = pkgs-stable.azure-cli.withExtensions (with pkgs.azure-cli-extensions; [fzf ai-examples azure-devops]);
in {
  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix {inherit config pkgs pkgs-stable inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    #../../linux/vpn.nix
  ];

  environment.systemPackages = [
    pkgs.unixODBC
    pkgs.unixODBCDrivers.msodbcsql17
    # pkgs.plantuml
    # pkgs.icu
    # pkgs.dotnet-sdk_8
    # pkgs.azure-cli
    #  az-cli-with-extensions
    pkgs.xdummy
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
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true; # Enables starting X server manually
  services.xserver.videoDrivers = ["dummy"];
}
