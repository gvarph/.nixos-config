{...}: {
  # Lock screen for Hyprland.
  # The Catppuccin module (autoEnable) sources the Mocha palette and defines
  # $accent/$accentAlpha (= mauve, the default accent), replacing the old
  # manually-maintained mocha.conf.
  programs.hyprlock = {
    enable = true;

    settings = {
      "$font" = "JetBrains Mono Nerd Font";

      general = {
        disable_loading_bar = true;
        grace = 0;
        hide_cursor = true;
        no_fade_in = false;
      };

      # Background - using base color instead of pure black
      background = [
        {
          monitor = "";
          path = "";
          color = "$base";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 60";
          outline_thickness = 4;
          dots_size = 0.2;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "$accent";
          inner_color = "$surface0";
          font_color = "$text";
          fade_on_empty = false;
          placeholder_text = "<span foreground=\"##$textAlpha\"><i>󰌾 Logged in as </i><span foreground=\"##$accentAlpha\">$USER</span></span>";
          hide_input = false;
          check_color = "$accent";
          fail_color = "$red";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          capslock_color = "$yellow";
          position = "0, -47";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        # Time
        {
          monitor = "";
          text = "$TIME";
          color = "$text";
          font_size = 90;
          font_family = "$font";
          position = "-30, 0";
          halign = "right";
          valign = "top";
        }
        # Date
        {
          monitor = "";
          text = "cmd[update:43200000] date +\"%A, %d %B %Y\"";
          color = "$text";
          font_size = 25;
          font_family = "$font";
          position = "-30, -150";
          halign = "right";
          valign = "top";
        }
        # Keyboard layout
        {
          monitor = "";
          text = "Layout: $LAYOUT";
          color = "$text";
          font_size = 25;
          font_family = "$font";
          position = "30, -30";
          halign = "left";
          valign = "top";
        }
      ];
    };
  };

  # Only take the palette + accent from Catppuccin; its full default hyprlock
  # layout would be added on top of the one above.
  catppuccin.hyprlock.useDefaultConfig = false;
}
