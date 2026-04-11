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

    whatsapp-electron
  ];

  imports = [
    #   ./work.nix
    ./obsidian.nix
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

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
    plugins = {
      dragon =
        pkgs.fetchFromGitHub {
          owner = "R4Sput1n";
          repo = "yazi-dragon";
          rev = "67f9844946e3fbfd7b3535e6ffb7327c5a69c82f";
          hash = "sha256-nPMMXtxYPFsTAvMbmR/LVAV9KdhV3TEYfnoDoSIEETI=";
        }
        + "/dragon.yazi";
    };
  };
}
