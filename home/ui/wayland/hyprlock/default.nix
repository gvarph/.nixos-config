{pkgs, ...}: {
  # Install hyprlock package
  # Config is in ~/.config/hypr/hyprlock.conf (symlinked from repo)
  home.packages = [pkgs.hyprlock];
}
