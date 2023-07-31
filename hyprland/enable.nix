{pkgs, ...}: {

  imports = [
    ./sound.nix
  ];
  
  programs.hyprland= {
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
    pkgs.dunst
    pkgs.libnotify
    pkgs.rofi-wayland
    pkgs.firefox
    pkgs.networkmanagerapplet
    pkgs.wl-clipboard 
    pkgs.grim #screenshot
    pkgs.slurp #select part of screen

  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk ];

}
