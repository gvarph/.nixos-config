{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia.homeModules.default
  ];
  # configure options
  programs.noctalia-shell = {
    enable = true;
    settings = {
      # configure noctalia here
      bar = {
        density = "normal";
        position = "top";
        showCapsule = false;
        widgetsSpacing = 6;

        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {
              id = "Workspace";
              emptyColor = "tertiary";
              hideUnoccupied = true;
              labelMode = "index";
              occupiedColor = "secondary";
              pillSize = 0.75;
              showApplications = true;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 0.5;
              groupedBorderOpacity = 0.5;
              iconScale = 0.7;
              characterCount = 1;
              followFocusedScreen = false;
            }
          ];
          center = [
            {
              id = "AudioVisualizer";
              hideWhenIdle = true;
              colorName = "primary";
            }
          ];
          right = [
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "VPN";
              textColor = "none";
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
              textColor = "none";
            }
            {
              deviceNativePath = "__default__";
              displayMode = "graphic-clean";
              hideIfIdle = false;
              hideIfNotDetected = true;
              id = "Battery";
              showNoctaliaPerformance = false;
              showPowerProfiles = false;
            }
            {
              displayMode = "alwaysShow";
              iconColor = "none";
              id = "Network";
              textColor = "none";
            }
            {
              clockColor = "none";
              customFont = "";
              formatHorizontal = "HH:mm:ss";
              formatVertical = "HH mm";
              id = "Clock";
              tooltipFormat = "yyyy-MM-dd HH:mm:ss";
              useCustomFont = false;
            }
          ];
        };
      };

      general = {
        lockScreenBlur = 0.1;
        lockScreenMonitors = ["HDMI-A-1"];
      };
      wallpaper = {enable = false;};

      colorSchemes = {
        useWallpaperColors = false;
        predefinedScheme = "Catppuccin";
        darkMode = true;
        schedulingMode = "off";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        generationMethod = "tonal-spot";
        monitorForColors = "";
      };

      location = {
        monthBeforeDay = true;
        name = "Prague, Czech Republic";
      };
    };
    # this may also be a string or a path to a JSON file.
  };
}
