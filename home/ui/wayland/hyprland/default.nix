{
  pkgs,
  custom,
  ...
}: let
  flake-compat = builtins.fetchTarball "https://github.com/edolstra/flake-compat/archive/master.tar.gz";

  hyprland =
    (import flake-compat {
      src = builtins.fetchTarball "https://github.com/hyprwm/Hyprland/archive/master.tar.gz";
    })
    .defaultNix;
in {
  imports = [
    hyprland.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    hyprpaper
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    enableNvidiaPatches = true;
    xwayland = {
      enable = true;
      #hidpi = true;
    };
    extraConfig =
      custom.hypr_monitors
      + (builtins.readFile ./keybinds.conf)
      + (builtins.readFile ./nav_keybinds.conf)
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
