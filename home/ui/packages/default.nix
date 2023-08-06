{ pkgs, ... }:
{

  home.packages = with pkgs; [
    vscode

    discord
    betterdiscordctl

    libnotify

    firefox

    steam
    lutris
    prismlauncher

    pulseaudio

    slack

    thunderbird
    okular
    libsForQt5.kdeconnect-kde


    ledger-live-desktop

  ];

  imports = [
    #(import ./thing { inherit pkgs custom; })
  ];
}
