{pkgs, ...}: {
  home.packages = with pkgs; [
    pulseaudio

    zen-browser

    r2modman

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
  };
}
