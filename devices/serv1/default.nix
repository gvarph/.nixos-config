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

    # ../../default.nix already imports docker.nix
    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../modules/nix-maintenance.nix
    (import ../../modules/boot-systemd.nix {kernelPackages = pkgs.linuxPackages_latest;})
    ../../linux/features/kubernetes.nix
    # 9100 is taken by the k3s victoria-metrics stack's hostNetwork node exporter.
    (import ../../modules/push-metrics.nix {port = 9101;})
    (import ../../modules/hibernation.nix {
      swapfile = {
        sizeGiB = 64;
        resumeDevice = "/dev/disk/by-uuid/1f4f533d-e209-4cde-ae13-ab6656a11cc2";
        resumeOffset = 16537600;
      };
    })
  ];

  environment.systemPackages = [
    pkgs.xdummy
  ];

  # azure-cli is only used on serv1, and it's a big closure that regularly
  # misses the binary cache — keep it off the other hosts.
  home-manager.users.${username}.imports = [../../home/programs/az-cli];

  networking.hostName = "serv1";
  networking.networkmanager.enable = true;

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

  networking.interfaces.enp0s31f6.wakeOnLan.enable = true;
}
