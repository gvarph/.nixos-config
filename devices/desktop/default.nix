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
    ./audio.nix

    (import ../../default.nix {inherit config pkgs inputs username;})
    (import ../../home/ui {inherit pkgs username;})
    ../../linux/fonts.nix
    ../../linux/features/gaming.nix
    (import ./steamvr-exporter.nix {inherit username;})
    ./metrics.nix
    ../../modules/nix-maintenance.nix
    (import ../../modules/boot-systemd.nix {kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;})
    # The installer's encrypted swap partition (nvme0n1p3, ~34G > RAM).
    (import ../../modules/hibernation.nix {
      luksPartitionUuid = "5f00d327-44e5-4daf-8e76-7ca3f7b90516";
    })
  ];

  # Default shader cache is 1G, which thrashes with big Vulkan titles.
  environment.sessionVariables.MESA_SHADER_CACHE_MAX_SIZE = "16G";

  networking.hostName = "desktop";
  networking.networkmanager.enable = true;
  # Keep Wi-Fi adapters awake: power saving adds latency spikes to VR
  # streaming over the Steam Frame wireless adapter.
  networking.networkmanager.wifi.powersave = false;

  nix.settings = {
    # Binary cache for the CachyOS kernel (nix-cachyos-kernel's `release`
    # branch only advances once the kernel is in it). It moved from
    # attic.xuyh0120.win, which now answers 400 "Binary cache migrated":
    # https://github.com/xddxdd/nix-cachyos-kernel/issues/110
    extra-substituters = ["https://cache.lantian.pub/lantian"];
    extra-trusted-public-keys = ["lantian:WVGO7vsRMSEN+h7Lp7kv6SAmrkEXgUGbbXm7jMDjBuQ="];
    # Dedupe at build time instead of the nix-optimise timer (disabled below).
    auto-optimise-store = true;
  };

  # The optimise timer is Persistent, so on a desktop that's off at 03:45 it runs
  # right after boot; the cgroup writeback inode switch it leaves behind pins
  # kworkers at 100% and freezes the desktop for ~40 min.
  nix.optimise.automatic = lib.mkForce false;

  # Framebuffer resolution for console (fixes small quadrant issue on 4K)
  boot.kernelParams = ["video=3840x2160@60"];

  # Console font for 4K display
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
    packages = with pkgs; [terminus_font];
    earlySetup = true;
  };

  # hid_apple: Apple keyboard fn mode (2 = F-keys first).
  # cfg80211: Wi-Fi regulatory domain. Without a country the kernel stays on
  # the world domain ("00"), where 6 GHz is disabled; the Steam Frame
  # wireless adapter needs that band.
  boot.extraModprobeConfig = ''
    options hid_apple fnmode=2
    options cfg80211 ieee80211_regdom=CZ
  '';

  networking.firewall = {
    enable = true;
    # Sunshine ports come from services.sunshine.openFirewall,
    # mDNS (5353) from services.avahi.openFirewall
    allowedTCPPorts = [
      80
      443
      1194
      1195
      3003
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

  # SteamVR as the OpenXR runtime (wiki.nixos.org/wiki/VR); without it OpenXR games exit at launch.
  # Absolute library_path: SteamVR's own manifest uses a relative one that breaks when symlinked.
  home-manager.users.${username} = {config, ...}: {
    xdg.configFile."openxr/1/active_runtime.json".text = builtins.toJSON {
      file_format_version = "1.0.0";
      runtime = {
        VALVE_runtime_is_steamvr = true;
        name = "SteamVR";
        library_path = "${config.home.homeDirectory}/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    vulkan-tools

    rocmPackages.clr
    awakened-poe-trade
    frame-control

    android-tools
  ];

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

  # Mesa comes from Hyprland's pinned nixpkgs, not ours. Hyprland loads the
  # system GBM driver from /run/opengl-driver; when our nixpkgs bumps glibc
  # ahead of Hyprland's, that Mesa needs a newer glibc than Hyprland was built
  # with and the compositor aborts at startup (CBackend::create() failed).
  hardware.graphics = let
    hyprlandPkgs = inputs.hyprland.inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  in {
    enable = true;
    enable32Bit = true;
    package = hyprlandPkgs.mesa;
    package32 = hyprlandPkgs.pkgsi686Linux.mesa;
  };

  services.lact.enable = true;

  # Firmware updates from LVFS: `fwupdmgr refresh && fwupdmgr get-updates`.
  services.fwupd.enable = true;

  # D-Bus daemon that mounts removable media; the user-level udiskie service
  # (home/ui/wayland/udiskie) drives it to auto-mount USB drives on insert.
  services.udisks2.enable = true;

  # services.sunshine = {
  #   enable = true;
  #   autoStart = true;
  #   capSysAdmin = true;
  #   openFirewall = true;
  # };
  # programs.kdeconnect.enable = true;

  programs.appimage.binfmt = true;
}
