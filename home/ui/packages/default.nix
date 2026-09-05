{pkgs, ...}: {
  imports = [
    ./ghostty.nix
    ./yazi.nix
  ];

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

    # Qt theming config tool; QT_QPA_PLATFORMTHEME=qt6ct is set in hyprland/input.nix
    qt6Packages.qt6ct

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

    thunar
  ];

  programs.vesktop.enable = true;
}
