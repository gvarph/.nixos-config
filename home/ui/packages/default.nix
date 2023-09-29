{ pkgs, ... }:
{

  home.packages = with pkgs; [

    discord
    betterdiscordctl

    libnotify

    firefox
    google-chrome


    steam
    lutris
    prismlauncher
    wineWowPackages.stable

    pulseaudio

    slack

    thunderbird
    okular
    libsForQt5.kdeconnect-kde


    ledger-live-desktop
    transmission-gtk
    playerctl
    wev
    signal-desktop
  ];

  imports = [
    ./work.nix
  ];

}
