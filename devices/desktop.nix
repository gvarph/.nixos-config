{ config, lib, pkgs, username, ... }:

let
  username = "gvarph";
  gpuId = "10de:1f02";
  soundId = "10de:10f9";
in
{

  imports = [
    (import ../default.nix { inherit config pkgs username; })
    ../system/features/docker.nix
    ../system/filesystem/nas/mount.nix
    (import ../home/ui { inherit config pkgs username; })
    #(import ../system/vm.nix { inherit config pkgs username gpuId soundId; })

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


  services.udev.packages = [ pkgs.ledger-live-desktop ];

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
