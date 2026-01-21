{
  pkgs,
  custom,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
  };
}
