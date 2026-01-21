{
  pkgs,
  custom,
  ...
}: {
  home.packages = with pkgs; [
    kitty
    ghostty
  ];

  imports = [
    ./hyprland
    # (import ./waybar {inherit pkgs custom;})
    ./wofi.nix
    # (import ./foot.nix {inherit custom;})
  ];
}
