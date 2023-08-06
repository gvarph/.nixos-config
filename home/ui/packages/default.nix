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
    #(import ./hyprland { inherit pkgs custom; })
    #(import ./waybar { inherit custom; })
    #(import ./wofi.nix { inherit custom; })
    #(import ./foot.nix { inherit custom; })
  ];
}
