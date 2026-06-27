{...}: {
  # Automounts removable media (USB flash drives, SD cards, etc.) on insert.
  # Talks to the system udisks2 daemon (enabled in the device config), so no
  # root/password prompt is needed for the active graphical session.
  #
  # Runs as a systemd user service bound to graphical-session.target, so UWSM
  # starts it automatically on login (same wiring as services.mako).
  services.udiskie = {
    enable = true;
    automount = true; # mount drives as soon as they appear
    notify = true; # toast via mako when a drive is mounted/unmounted
    tray = "auto"; # show a tray icon only when a status-notifier tray exists
  };
}
