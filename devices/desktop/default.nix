{ lib, pkgs, username, config, ... }:
let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
  base = "../..";
  hypr_monitors = (builtins.readFile ./hypr_monitors.conf);
in
{
  imports = [
    (import ../../default.nix {
      inherit config pkgs username;
    })
    ../../system/features/docker.nix
    ../../system/filesystem/nas/mount.nix
    ../../system/nvidia.nix
    (import ../../home/ui { inherit pkgs username hypr_monitors; })
  ];

  networking.hostName = "deskt";
  networking.networkmanager.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; } # KDE Connect \
    ];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; } # KDE Connect
    ];
  };


}
