{...}: {
  # Keybindings: basic binds for common actions
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "dolphin";
    "$menu" = "rofi -show drun";

    bind = [
      # Application shortcuts
      "$mod, Q, exec, uwsm app -- $terminal"
      "$mod, E, exec, uwsm app -- $fileManager"
      "$mod, R, exec, uwsm app -- $menu"
      "ALT, SPACE, exec, uwsm app -- $menu"
      # cliphist history with image thumbnails
      "$mod, V, exec, clipboard-picker"

      # Window management
      "$mod, C, killactive,"
      "$mod, M, exit,"
      "$mod, W, togglefloating,"
      "$mod, P, pseudo," # dwindle
      "$mod, T, layoutmsg, togglesplit" # dwindle
      "$mod, F, fullscreen, 0"
      "$mod, Escape, exec, hyprlock" # Lock screen

      # Move focus with arrow keys
      "$mod, left, movefocus, l"
      "$mod, right, movefocus, r"
      "$mod, up, movefocus, u"
      "$mod, down, movefocus, d"

      # Move focus with vim keys
      "$mod, H, movefocus, l"
      "$mod, L, movefocus, r"
      "$mod, K, movefocus, u"
      "$mod, J, movefocus, d"

      # Move windows with SHIFT + arrow keys
      "$mod SHIFT, left, movewindow, l"
      "$mod SHIFT, right, movewindow, r"
      "$mod SHIFT, up, movewindow, u"
      "$mod SHIFT, down, movewindow, d"

      # Switch workspaces with number keys
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"

      # Move active window to workspace
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      # Move window to workspace silently (don't switch)
      "$mod CTRL SHIFT, 1, movetoworkspacesilent, 1"
      "$mod CTRL SHIFT, 2, movetoworkspacesilent, 2"
      "$mod CTRL SHIFT, 3, movetoworkspacesilent, 3"
      "$mod CTRL SHIFT, 4, movetoworkspacesilent, 4"
      "$mod CTRL SHIFT, 5, movetoworkspacesilent, 5"
      "$mod CTRL SHIFT, 6, movetoworkspacesilent, 6"
      "$mod CTRL SHIFT, 7, movetoworkspacesilent, 7"
      "$mod CTRL SHIFT, 8, movetoworkspacesilent, 8"
      "$mod CTRL SHIFT, 9, movetoworkspacesilent, 9"
      "$mod CTRL SHIFT, 0, movetoworkspacesilent, 10"

      # Scroll through workspaces
      "$mod, mouse_down, workspace, e+1"
      "$mod, mouse_up, workspace, e-1"

      # Screenshot (requires grim and slurp)
      "$mod SHIFT, S, exec, grim -g \"$(slurp)\" - | wl-copy"
      ", Print, exec, grim - | wl-copy"
      "SHIFT, Print, exec, grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"

      # Media keys
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    # Repeating binds (held keys keep firing)
    binde = [
      # Resize windows with CTRL + arrow keys
      "$mod CTRL, left, resizeactive, -50 0"
      "$mod CTRL, right, resizeactive, 50 0"
      "$mod CTRL, up, resizeactive, 0 -50"
      "$mod CTRL, down, resizeactive, 0 50"

      # Volume
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

      # Brightness control
      ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];

    # Move/resize windows with mouse
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
  };
}
