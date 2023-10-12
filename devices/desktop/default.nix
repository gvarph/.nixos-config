{ lib, pkgs, username, config, ... }:
let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
  base = "../..";
  hypr_monitors = (builtins.readFile ./hypr_monitors.conf);
  secrets = import /etc/nixos/secrets.nix;
in
{
  imports = [
    (import ../../default.nix {
      inherit config pkgs username;
    })
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../linux/nvidia.nix
    (import ../../home/ui { inherit pkgs username hypr_monitors; })
  ];

  networking.hostName = "deskt";
  networking.networkmanager.enable = true;



  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.firewall = {
    enable = false;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; } # KDE Connect \
    ];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; } # KDE Connect
    ];
  };

  services.openvpn.servers = {
    officeVPN = {
      config = '' config /etc/nixos/secrets/bizmachine_new.ovpn '';
      authUserPass.username = secrets.office-vpn-login.username;
      authUserPass.password = secrets.office-vpn-login.password;
      autoStart = false;
    };
  };

}
