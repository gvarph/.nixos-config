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
    # (import ./wofi.nix {inherit custom;})
    # (import ./foot.nix {inherit custom;})
  ];
}
