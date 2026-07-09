{...}: {
  # Input devices, layouts, environment variables
  wayland.windowManager.hyprland.settings = {
    env = [
      "XCURSOR_SIZE,24"
      "QT_QPA_PLATFORMTHEME,qt6ct"
      "NIXOS_OZONE_WL,1"
    ];

    input = {
      kb_layout = "us";

      follow_mouse = 2;

      touchpad = {
        natural_scroll = false;
        disable_while_typing = true;
        "tap-to-click" = true;
      };

      sensitivity = 0; # -1.0 to 1.0, 0 means no modification
      accel_profile = "flat";
    };

    # Dwindle layout
    dwindle = {
      preserve_split = true;
      smart_split = false;
      smart_resizing = true;
    };

    # Master layout
    master = {
      new_status = "master";
      new_on_top = false;
    };
  };
}
