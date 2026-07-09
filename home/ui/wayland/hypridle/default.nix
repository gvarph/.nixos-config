{...}: {
  # Idle management for Hyprland
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # turn on displays after resume
        ignore_dbus_inhibit = false;
      };

      listener = [
        # Lock screen after 5 minutes
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # Turn off displays after 10 minutes
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # Optional: Suspend system after 30 minutes (uncomment if desired)
        # {
        #   timeout = 1800;
        #   on-timeout = "systemctl suspend";
        # }
      ];
    };
  };
}
