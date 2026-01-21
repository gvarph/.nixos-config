{
  config,
  pkgs,
  custom,
  ...
}: let
  # Get the absolute path to the config directory in your repo
  configDir = "${config.home.homeDirectory}/.nixos-config/home/ui/wayland/hyprland/config";
in {
  # wayland.windowManager.hyprland = {
  #   enable = true;
  #   # Configuration is in hyprland.conf which is symlinked from the repo
  #   # This allows you to edit it without rebuilding!
  # };

  # Create an out-of-store symlink to the config file
  # This means changes to hyprland.conf take effect immediately without rebuilding
  xdg.configFile."hypr".source =
    config.lib.file.mkOutOfStoreSymlink configDir;
}
