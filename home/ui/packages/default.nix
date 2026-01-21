{pkgs, ...}: {
  home.packages = with pkgs; [
    # discord
    # betterdiscordctl
    #
    # libnotify
    #
    zen-browser
    # google-chrome
    #
    # vscode
    # steam
    # lutris
    # prismlauncher
    # wineWowPackages.stable
    #
    # pulseaudio
    #
    # slack
    #
    # thunderbird
    # okular
    # libsForQt5.kdeconnect-kde
    #
    # ledger-live-desktop
    # transmission-gtk
    # playerctl
    # wev
    # signal-desktop
  ];

  imports = [
    #   ./work.nix
  ];
  programs.vesktop.enable = true;
  programs.hyprpanel.enable = true;
}
