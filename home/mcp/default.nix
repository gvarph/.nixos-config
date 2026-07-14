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
  pwUserDataDir = "${config.home.homeDirectory}/.local/share/playwright-mcp/profile";

  # The chromium-<rev> subdir version changes whenever nixpkgs bumps
  # playwright-driver, so resolve it with a glob at launch time rather than
  # hardcoding the revision (which used to go stale and silently break the
  # browser on every update). The store path itself stays nix-pinned, so this
  # is still fully reproducible; only the version subdir is discovered. The
  # glob matches chromium-<rev> but not chromium_headless_shell-<rev>.
  playwrightMcpWrapped = pkgs.writeShellScriptBin "playwright-mcp-wrapped" ''
    set -euo pipefail
    shopt -s nullglob
    matches=(${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux64/chrome)
    if [ ''${#matches[@]} -eq 0 ]; then
      echo "playwright-mcp: no chromium-* found in ${pkgs.playwright-driver.browsers}" >&2
      exit 1
    fi
    exec ${pkgs.playwright-mcp}/bin/playwright-mcp \
      --browser chromium \
      --executable-path "''${matches[0]}" \
      --user-data-dir "${pwUserDataDir}" \
      "$@"
  '';
in {
  home.packages = with pkgs; [
    playwright-mcp
  ];

  programs.mcp = {
    enable = true;
    servers =
      {
        # "http" is the streamable-HTTP transport Claude Code expects for
        # remote servers; "remote" is NOT a valid type (Claude Code silently
        # drops the server and it never shows in /mcp).
        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
        };
        # Self-hosted TREK trip planner's built-in MCP endpoint. Auth is TREK's
        # own OAuth 2.1: Claude Code runs the browser consent flow on first
        # connect, so there's no token/header to configure here. Not behind the
        # oauth2-proxy gateway (that would hijack the MCP OAuth flow).
        trek = {
          type = "http";
          url = "https://trek.gvarph.com/mcp";
        };
        playwright = {
          command = "${playwrightMcpWrapped}/bin/playwright-mcp-wrapped";
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
        gcloud = {
          command = "${gcloudMcp}/bin/gcloud-mcp-wrapped";
        };
      };
  };
}
