{...}: {
  # Visual settings: borders, gaps, colors, animations, window/layer rules
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in = 5;
      gaps_out = 10;
      border_size = 2;

      # Gradient border colors (blue to teal)
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";

      layout = "dwindle";
      allow_tearing = false;
    };

    # No gaps when there's only one window in a workspace
    workspace = [
      "w[tv1], gapsout:0, gapsin:0"
      "f[1], gapsout:0, gapsin:0"
    ];

    windowrule = [
      # Borderless + square when a workspace has a single tiled window…
      # (block-form windowrules require a name as their key)
      {
        name = "seamless-single-window";
        border_size = 0;
        rounding = 0;
        "match:float" = 0;
        "match:workspace" = "w[tv1]";
      }
      # …or a fullscreen one
      {
        name = "seamless-fullscreen";
        border_size = 0;
        rounding = 0;
        "match:float" = 0;
        "match:workspace" = "f[1]";
      }
      # Float pavucontrol as a centered popup
      {
        name = "pavucontrol-popup";
        "match:class" = "org.pulseaudio.pavucontrol";
        float = true;
        size = "800 600";
        center = true;
      }
      # Awakened PoE Trade: floating overlay with no chrome or effects
      {
        name = "apt-rule";
        "match:class" = "^(awakened-poe-trade|Awakened-poe-trade)$";
        float = true;
        border_size = 0;
        no_blur = true;
        no_shadow = true;
        no_anim = true;
        # might be unnecessary
        no_follow_mouse = true;
      }
    ];

    decoration = {
      rounding = 10;

      blur = {
        enabled = true;
        size = 8;
        passes = 2;
        new_optimizations = true;
        # Blur layer-shell popups (menus, tooltips) too
        popups = true;
      };
    };

    layerrule = [
      # Blur the rofi launcher so it matches the window blur
      "blur true, match:namespace rofi"
      "ignore_alpha 0.5, match:namespace rofi"
      # No animation, so the launcher snaps instead of animating its resize as you type
      "no_anim true, match:namespace rofi"

      # Waybar: its bar background is already translucent (rgba .3), so blur
      # what's behind it; low ignore_alpha so the faint bar bg still blurs
      "blur true, match:namespace waybar"
      "ignore_alpha 0.2, match:namespace waybar"

      # Mako notifications (translucency set in mako's own config)
      "blur true, match:namespace notifications"
      "ignore_alpha 0.5, match:namespace notifications"
    ];

    animations = {
      enabled = true;

      # Custom bezier curves
      bezier = [
        "myBezier, 0.05, 0.9, 0.1, 1.05"
        "smoothOut, 0.36, 0, 0.66, -0.56"
        "smoothIn, 0.25, 1, 0.5, 1"
      ];

      animation = [
        "windows, 1, 7, myBezier, slide"
        "windowsOut, 1, 7, smoothOut, slide"
        "windowsMove, 1, 6, myBezier, slide"
        "border, 1, 10, default"
        "borderangle, 1, 8, default"
        "fade, 1, 7, smoothIn"
        "fadeDim, 1, 7, smoothIn"
        "workspaces, 1, 6, default"
      ];
    };
  };
}
