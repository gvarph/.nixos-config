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
    cliphist

    whatsapp-electron

    (prismlauncher.override {
      # Add binary required by some mod
      additionalPrograms = [ffmpeg];

      # Change Java runtimes available to Prism Launcher
      jdks = [
        graalvmPackages.graalvm-ce
        jdk25
        jdk21
        jdk17
      ];
    })
  ];

  imports = [
    ./ghostty.nix
  ];
  programs.vesktop.enable = true;

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
