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
    ./disko
    ./nginx.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    ../../linux/features/docker.nix
    ../../linux/filesystem/nas/mount.nix
    ../../secrets/age.nix
    ../../modules/nix-maintenance.nix
    ../../modules/boot-systemd.nix
    #../../linux/features/kubernetes.nix
  ];

  networking.hostName = "nas1";
  networking.networkmanager.enable = true;
  networking.hostId = "f531fbde"; # 8 hex characters, stable

  environment.systemPackages = with pkgs; [
    smartmontools
    powertop
  ];

  powerManagement.powertop.enable = true;
  boot.supportedFilesystems = ["zfs"];

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.firewall.allowedTCPPorts = [80 443];

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
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD"; # Prefer the modern iHD backend
    # VDPAU_DRIVER = "va_gl";      # Only if using libvdpau-va-gl
  };

  # May help if FFmpeg/VAAPI/QSV init fails (esp. on Arc with i915):
  hardware.enableRedistributableFirmware = true;
  boot.kernelParams = ["i915.enable_guc=3"];

  boot.initrd.supportedFilesystems = ["zfs"];

  age.secrets.cloudflare_dns_api_token.file = ../../secrets/cloudflare_dns_api_token.age;
}
