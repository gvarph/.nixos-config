{
  pkgs,
  custom,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    microsoft-edge
    mongodb-compass
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
}
