{
  config,
  pkgs,
  lib,
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
    servers = {
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
    };
  };
}
