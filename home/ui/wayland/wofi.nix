{pkgs, ...}: {
  programs.rofi = {
    enable = true;
    font = "FiraCode Nerd Font";
    terminal = "ghostty";
    plugins = [
      pkgs.rofi-calc
    ];
  };
}
