{pkgs, ...}: {
  home.packages = with pkgs; [
    pulseaudio
    libation
    libreoffice

    zen-browser
    qbittorrent-enhanced

    r2modman
    rusty-path-of-building

    slurp
    grim
    wl-clipboard
  ];

  imports = [
    #   ./work.nix
  ];
  programs.vesktop.enable = true;

  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      mouse-scroll-multiplier = 0.5;
      term = "xterm-256color";
      font-family = "FiraCode Nerd Font";
    };
  };
}
