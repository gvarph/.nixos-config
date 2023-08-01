{ pkgs, ... }: {

  imports = [
    ./sound.nix
    #./waybar.nix
  ];

  programs.hyprland = {
    enable = true;
    nvidiaPatches = true;
    xwayland.enable = true;


  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };
  environment.systemPackages = [
    pkgs.waybar
    pkgs.kitty
    pkgs.vscode
    pkgs.discord
    pkgs.betterdiscordctl
    pkgs.dunst
    pkgs.libnotify
    pkgs.rofi-wayland
    pkgs.firefox
    pkgs.networkmanagerapplet
    pkgs.wl-clipboard
    pkgs.grim #screenshot
    pkgs.slurp #select part of screen

    pkgs.steam
    pkgs.lutris

    pkgs.prismlauncher
    pkgs.cinnamon.nemo
    pkgs.piper
    pkgs.libratbag
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };


  hardware.logitech.enable = true;
  hardware.logitech.enableGraphical = true; # for solaar to be included

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

}
