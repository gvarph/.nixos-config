{
  config,
  pkgs,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    ./hardware-configuration.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../secrets/age.nix
    #../../linux/features/kubernetes.nix
  ];

  networking.hostName = "serv2";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix = {
    optimise = {
      automatic = true;
      dates = ["03:45"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Cron job to start audiobook shelf container every 5 minutes if not running
  services.cron = {
    enable = true;
    systemCronJobs = [
      "*/5 * * * * root ${pkgs.docker}/bin/docker start audiobookshelf-audiobookshelf-1 || true"
    ];
  };
}
