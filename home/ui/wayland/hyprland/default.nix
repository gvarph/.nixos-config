{ pkgs
, custom ? {
    fontsize = "12";
    primary_accent = "cba6f7";
    secondary_accent = "89b4fa";
    tertiary_accent = "f5f5f5";
    background = "11111B";
    opacity = ".85";
    cursor = "Numix-Cursor";
  }
, ...
}:
let
  flake-compat = builtins.fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz";

  hyprland = (import flake-compat {
    src = builtins.fetchTarball "https://github.com/hyprwm/Hyprland/archive/master.tar.gz";
  }).defaultNix;
in
{
  imports = [
    hyprland.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    hyprpaper
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    nvidiaPatches = true;
    xwayland = {
      enable = true;
      hidpi = true;
    };
    extraConfig = (builtins.readFile ./monitors.conf)
      + (builtins.readFile ./keybinds.conf)
      + (builtins.readFile ./theme.conf)
      + (builtins.readFile ./other.conf)
      + ''
      exec-once=nm-applet --indicator
      exec-once=waybar
      exec-once=dunst
      exec-once=copyq --start-server
    '';

  };

}
