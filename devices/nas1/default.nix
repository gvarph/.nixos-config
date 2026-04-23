{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  username = "gvarph";
in {
  imports = [
    ./hardware-configuration.nix
    ./disko
    ./nginx.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../linux/features/docker.nix
    ../../modules/nix-maintenance.nix
    (import ../../modules/boot-systemd.nix {kernelPackages = pkgs.linuxPackages_6_19;})
    #../../linux/features/kubernetes.nix
  ];

  networking.hostName = "nas1";
  networking.networkmanager.enable = true;
  networking.hostId = "f531fbde"; # 8 hex characters, stable

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
    lm_sensors
  ];

  powerManagement.powertop.enable = true;
  boot.supportedFilesystems = ["zfs"];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      80 # HTTP (general device APIs / fallback)
      443 # HTTPS (general device APIs / fallback)

      1400 # Sonos control API
      8008 # Chromecast HTTP control
      8009 # Chromecast HTTPS/control
    ];
    allowedUDPPorts = [
      5353 # mDNS (multicast discovery for Chromecast, AirPlay, some Sonos features)
      1900 # SSDP/UPnP (Sonos discovery)
    ];

    allowedTCPPortRanges = [
      {
        from = 8000;
        to = 65535;
      }
    ];

    # allowedUDPPortRanges = [
    #   {
    #     from = 8000;
    #     to = 65535;
    #   }
    # ];
  };

  services.xserver.videoDrivers = ["modesetting"];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # Required for modern Intel GPUs (Xe iGPU and ARC)
      intel-media-driver # VA-API (iHD) userspace
      vpl-gpu-rt # oneVPL (QSV) runtime

      # Optional (compute / tooling):
      intel-compute-runtime # OpenCL (NEO) + Level Zero for Arc/Xe
      # NOTE: 'intel-ocl' also exists as a legacy package; not recommended for Arc/Xe.
      # libvdpau-va-gl       # Only if you must run VDPAU-only apps
      intel-vaapi-driver
      libva
      libva-utils
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
  };

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = ["i915.enable_guc=3"];

  boot.initrd.supportedFilesystems = ["zfs"];

  age.secrets.cloudflare_dns_api_token.file = ../../secrets/cloudflare_dns_api_token.age;
}
