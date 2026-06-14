{pkgs, ...}: {
  # Polkit authentication agent for Hyprland.
  # Provides the GUI password prompt for privileged actions
  # (mounting disks, nm-connection-editor changes, GParted, etc.).
  # Runs as a systemd user service bound to graphical-session.target.
  services.hyprpolkitagent.enable = true;
}
