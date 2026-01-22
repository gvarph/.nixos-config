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
    r2modman
  ];

  imports = [
    #   ./work.nix
  ];
  programs.vesktop.enable = true;
}
