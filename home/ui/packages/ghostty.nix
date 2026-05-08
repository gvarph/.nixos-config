{pkgs, ...}: {
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
