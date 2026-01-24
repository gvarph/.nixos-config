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
    # (import ./foot.nix {inherit custom;})
  ];
}
