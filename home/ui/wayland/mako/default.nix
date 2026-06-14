{...}: {
  # Catppuccin Mocha colors, applied through the catppuccin home-manager
  # module (already wired into the flake). This only sets the color keys;
  # behavioural settings live in services.mako.settings below.
  catppuccin = {
    flavor = "mocha";
    mako.enable = true;
  };

  # Non-intrusive notification daemon for Hyprland.
  # Runs as a systemd user service bound to graphical-session.target,
  # so UWSM starts it automatically on login.
  services.mako = {
    enable = true;
    settings = {
      "default-timeout" = 5000; # auto-dismiss after 5s
      anchor = "top-right";
      "max-visible" = 3; # cap concurrent toasts; rest queue
      "border-radius" = 8;
      "border-size" = 2;
      font = "FiraCode Nerd Font 11";
      width = 350;
      padding = 10;
      margin = 10;
    };
  };
}
