{ custom ? {
    font = "FiraCode Nerd Font";
    fontsize = "12";
    primary_accent = "cba6f7";
    secondary_accent = "89b4fa";
    tertiary_accent = "f5f5f5";
    background = "11111B";
    opacity = ".85";
    cursor = "Numix-Cursor";
  }
, ...
}:
{
  programs.waybar =
    {
      enable = true;
      settings.mainBar = {
        height = 30; # Waybar height (to be removed for auto height)
        marginTop = 6;
        layer = "top";
        marginLeft = 10;
        marginBottom = 0;
        marginRight = 10;
        spacing = 5; # Gaps between modules (4px)
        modules-left = [
          "custom/launcher"
          "wlr/workspaces"
        ];
        #modules-center = [ "custom/wallpaper" ];
        modules-right = [
          "tray"
          "cpu"
          "memory"

          #"bluetooth"
          "pulseaudio"
          "network"
          "hyprland/language"
          #"battery"
          "clock"
          # "custom/power-menu"
        ];
        "wlr/workspaces" = {
          format = "{icon}";
          onClick = "activate";
          format-icons = {
            "1" = "󰈹";
            "2" = "󰙯";
            "3" = "";
            "4" = "";
            "5" = "";
            urgent = "";
            active = "";
            default = "";
          };
        };
        "hyprland/window" = {
          format = "{}";
        };
        tray = { spacing = 10; };
        clock = {
          format = "<span color='#bf616a'> </span>{:%I:%H}";
          format-alt = "<span color='#bf616a'> </span>{:%a %b %d}";
          onClick = "~/.config/eww/scripts/toggle-onotify.sh";
        };
        cpu = {
          interval = 10;
          format = " {}%";
          maxLength = 10;
          onClick = "";
        };
        memory = {
          interval = 30;
          format = " {}%";
          format-alt = " {used:0.1f}G";
          maxLength = 10;
        };
        network = {
          format-wifi = "󰖩 {essid}";
          format-ethernet = "󰈀 wired";
          onClick = "alacritty -e nmtui";
          format-disconnected = "Disconnected  ";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = " {volume}%";
          format-bluetooth-muted = "  ";
          format-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
          onClick = "pavucontrol";
        };
        battery = {
          bat = "BAT1";
          adapter = "ADP0";
          interval = 60;
          states = {
            warning = 30;
            critical = 15;
          };
          maxLength = 20;
          format = "{icon} {capacity}%";
          format-warning = "{icon} {capacity}%";
          format-critical = "{icon} {capacity}%";
          format-charging = "<span font-family='Font Awesome 6 Free'></span> {capacity}%";
          format-plugged = "  {capacity}%";
          format-alt = "{icon} {time}";
          format-full = "  {capacity}%";
          format-icons = [ " " " " " " " " " " ];
        };
        bluetooth = {
          format = "";
          format-disabled = "";
          format-connected = "";
          onClick = "blueman-manager";
        };
        "custom/power-menu" = {
          format = " <span color='#6a92d7'>⏻ </span>";
          onClick = "wlogout --protocol layer-shell -b 5 -T 400 -B 400";
        };
        "custom/launcher" = {
          # TODO: add launcher
          format = " <span color='#6a92d7'></span>";
          onClick = "~/.config/eww/scripts/toggle-osettings.sh";
        };
        "custom/wallpaper" = {
          format = " <span color='#6a92d7'> </span>";
          onClick = "~/.bin/scripts/wallpaper.sh change";
        };
        "hyprland/language" = {
          format = " {short}";

        };

      };

      style = (builtins.readFile ./mocha.css) + (builtins.readFile ./style.css);

    };

}
