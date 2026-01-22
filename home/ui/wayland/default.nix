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
    ./waybar
    ./wofi.nix
    # (import ./foot.nix {inherit custom;})
  ];
}
