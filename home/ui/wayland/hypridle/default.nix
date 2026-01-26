{pkgs, ...}: {
  # Enable hypridle service
  # Config is in ~/.config/hypr/hypridle.conf (symlinked from repo)
  services.hypridle.enable = true;
}
