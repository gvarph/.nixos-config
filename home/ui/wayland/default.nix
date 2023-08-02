{ custom, ... }:
{
  imports = [
    (import ./hyprland { inherit custom; })
    (import ./waybar { inherit custom; })
    (import ./wofi.nix { inherit custom; })
    (import ./foot.nix { inherit custom; })
  ];
}
