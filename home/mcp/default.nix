{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: let
  # playwright-mcp bundles its browsers in the read-only nix store and, by
  # default, tries to fetch/create a "chrome-for-testing" build + profile dir
  # *inside* that store path -> mkdir EROFS on NixOS. We instead point it at the
  # Chromium that ships with playwright-driver.browsers (same store path the
  # playwright-mcp wrapper already exports as PLAYWRIGHT_BROWSERS_PATH) and give
  # it a writable user-data-dir under $HOME.
  #
  # NOTE: bump this revision when nixpkgs updates playwright-driver. Check with:
  #   ls ${pkgs.playwright-driver.browsers}
  chromeBin = "${pkgs.playwright-driver.browsers}/chromium-1217/chrome-linux64/chrome";
  pwUserDataDir = "${config.home.homeDirectory}/.local/share/playwright-mcp/profile";
in {
  home.packages = with pkgs; [
    playwright-mcp
  ];

  programs.mcp = {
    enable = true;
    servers =
      {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        playwright = {
          command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
          args = [
            "--browser"
            "chromium"
            "--executable-path"
            chromeBin
            "--user-data-dir"
            pwUserDataDir
          ];
          env = {
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          };
        };
      }
      # nas1 runs Grafana locally; this server is only useful while SSH'd into
      # it. Referencing osConfig.age.secrets.grafana_mcp_token (a nas1-only
      # secret) is safe because lib.optionalAttrs leaves the block unevaluated
      # on every other host. uv/uvx is pulled in via its store path so the
      # dependency is visible only to this server, not on the user's PATH.
      // lib.optionalAttrs (osConfig.networking.hostName == "nas1") {
        grafana = {
          command = "${pkgs.uv}/bin/uvx";
          args = ["mcp-grafana"];
          env = {
            GRAFANA_URL = "http://localhost:3000";
            GRAFANA_SERVICE_ACCOUNT_TOKEN.file = osConfig.age.secrets.grafana_mcp_token.path;
          };
        };
      };
  };
}
