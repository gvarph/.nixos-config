{
  pkgs,
  custom,
  ...
}: {
  home.packages = with pkgs; [
    ghostty
    microsoft-edge
  ];

  imports = [
    ./hyprland
    # (import ./waybar {inherit pkgs custom;})
    ./wofi.nix
    # (import ./foot.nix {inherit custom;})
  ];
}
