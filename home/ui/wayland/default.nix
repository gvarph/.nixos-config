{
  pkgs,
  custom,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    microsoft-edge
    mongodb-compass
    hyprcursor
  ];

  imports = [
    ./hyprland
    ./waybar
    ./wofi.nix
    ./hypridle
    ./hyprlock
    # (import ./foot.nix {inherit custom;})
    (import ./noctalia.nix {inherit pkgs inputs;})
  ];

  home.sessionVariables = {
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    ELECTRON_ENABLE_WAYLAND = "1";
  };

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
    gtk.enable = true;
    x11.enable = true;
    hyprcursor.enable = true;
  };
}
