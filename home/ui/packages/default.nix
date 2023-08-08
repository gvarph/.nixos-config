{ pkgs, ... }:
{

  home.packages = with pkgs; [
    vscode

    discord
    betterdiscordctl

    libnotify

    firefox
    google-chrome


    steam
    lutris
    prismlauncher

    pulseaudio

    slack

    thunderbird
    okular
    libsForQt5.kdeconnect-kde


    ledger-live-desktop

    playerctl
    wev

  ];

  imports = [
    ./work.nix
  ];

}
