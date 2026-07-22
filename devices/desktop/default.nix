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
    (import ../../home/ui {inherit pkgs username;})
    ../../linux/fonts.nix
    ../../linux/features/gaming.nix
    ../../modules/nix-maintenance.nix
    (import ../../modules/boot-systemd.nix {kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;})
  ];

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;

  # Binary cache for the CachyOS kernel (nix-cachyos-kernel) so it isn't
  # compiled from source on every kernel bump.
  nix.settings = {
    substituters = ["https://attic.xuyh0120.win/lantian"];
    trusted-substituters = ["https://attic.xuyh0120.win/lantian"];
    trusted-public-keys = ["lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="];
  };

  # Framebuffer resolution for console (fixes small quadrant issue on 4K)
  boot.kernelParams = ["video=3840x2160@60"];

  # Console font for 4K display
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
    packages = with pkgs; [terminus_font];
    earlySetup = true;
  };

  # Apple keyboard fn mode (2 = F-keys first)
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
  '';

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
      1194
      1195
      # Sunshine
      47984
      47989
      47990
      48010
      3003
    ];
    allowedUDPPorts = [
      5353 # mDNS (multicast discovery for Chromecast, AirPlay, some Sonos features)
    ];
    allowedUDPPortRanges = [
      {
        from = 4000;
        to = 4007;
      }
      {
        from = 8000;
        to = 8010;
      }
      # Sunshine
      {
        from = 47998;
        to = 48000;
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

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;

    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
        user = "greeter";
      };
    };
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    mullvad-vpn
    nvtopPackages.amd
    vulkan-tools

    rocmPackages.clr
  ];

  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprland.enableGnomeKeyring = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  hardware.xone.enable = true;

  boot.kernelModules = ["k10temp"];

  services.avahi = {
    enable = true;
    nssmdns4 = true; # Allows software to resolve .local names
    openFirewall = true; # Opens the mDNS port (5353)
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.lact.enable = true;

  # D-Bus daemon that mounts removable media; the user-level udiskie service
  # (home/ui/wayland/udiskie) drives it to auto-mount USB drives on insert.
  services.udisks2.enable = true;

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  programs.kdeconnect.enable = true;
}
