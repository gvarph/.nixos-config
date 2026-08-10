{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.herdr];

  # Out-of-store symlink, like waybar: theme and keybinding tweaks land with
  # `herdr server reload-config` instead of a rebuild.
  #
  # Only config.toml is linked, never the whole directory — ~/.config/herdr
  # also holds herdr's runtime state (herdr.sock, the *.log files,
  # session.json), which has to stay writable and out of git.
  xdg.configFile."herdr/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink
    "${config.home.homeDirectory}/.nixos-config/home/programs/herdr/config.toml";
}
