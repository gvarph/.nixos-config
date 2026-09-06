{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    # Catppuccin theme (catppuccin/zen-browser), symlinked into the profile's
    # chrome/catppuccin and loaded via userChrome/userContent imports.
    profiles.default = {
      presets.catppuccin = {
        enable = true;
        flavor = "Mocha"; # Frappe | Latte | Macchiato | Mocha
      };

      userChrome = ''
        profile-button {
          display: none !important;
        }
      '';

      search = {
        default = "ddg";

        engines = {
          github = {
            name = "GitHub Search";
            urls = [
              {
                template = "https://github.com/search?q={searchTerms}";
              }
            ];
            definedAliases = ["@gh"];
          };

          youtube = {
            name = "YouTube Search";
            urls = [
              {
                template = "https://www.youtube.com/results?search_query={searchTerms}";
              }
            ];
            definedAliases = ["@yt"];
          };
        };
      };
    };

    nativeMessagingHosts = [
      pkgs.firefoxpwa
    ];

    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;
    };

    # Betterfox for Zen (yokoffing/Betterfox zen/user.js, aka BetterZen):
    # privacy/telemetry/performance prefs applied as mkDefault settings —
    # any profile `settings` entry wins.
    profiles.default.presets.betterfox.enable = true;
  };
}
