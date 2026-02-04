{pkgs, ...}: {
  home.packages = with pkgs; [
    pulseaudio

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
    };
  };
}
