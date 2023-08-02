{ pkgs, custom, ... }:
{

  home.packages = with pkgs; [
    waybar
    dunst
    libnotify
    rofi-wayland
    networkmanagerapplet
    wl-clipboard
    grim #screenshot
    slurp #select part of screen

    cinnamon.nemo
    piper
    libratbag

    pavucontrol

    copyq



  ];

  imports = [
    (import ./hyprland { inherit pkgs custom; })
    (import ./waybar { inherit custom; })
    (import ./wofi.nix { inherit custom; })
    (import ./foot.nix { inherit custom; })
  ];
}
