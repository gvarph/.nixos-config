{
  pkgs,
  custom,
  ...
}: {
  home.packages = with pkgs; [
    microsoft-edge
  ];

  imports = [
    ./hyprland
    ./waybar
    ./wofi.nix
    ./hypridle
    ./hyprlock
    # (import ./foot.nix {inherit custom;})
  ];
}
