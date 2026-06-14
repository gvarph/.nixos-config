{
  pkgs,
  username,
  hypr_monitors ? "monitor=,preferred,auto,1",
  ...
}: let
  # Variables to share accross configs
  custom = {
    font = "FiraCode Nerd Font";
    fontsize = "12";
    primary_accent = "cba6f7";
    secondary_accent = "89b4fa";
    tertiary_accent = "f5f5f5";
    background = "11111B";
    opacity = ".85";
    cursor = "Numix-Cursor";
    hypr_monitors = hypr_monitors;
  };
in {
  home-manager.users.${username} = {
    imports = [
      (import ./wayland {inherit pkgs custom;})
      (import ./packages {inherit pkgs;})
    ];
  };
}
