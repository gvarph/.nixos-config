{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: let
  # We give playwright-mcp a writable user-data-dir under $HOME: it otherwise
  # tries to fetch/create a "chrome-for-testing" build + profile dir *inside*
  # the read-only nix store -> mkdir EROFS on NixOS.
  pwUserDataDir = "${config.home.homeDirectory}/.local/share/playwright-mcp/profile";

  # We run @playwright/mcp via npx rather than pkgs.playwright-mcp because
  # nixpkgs' playwright-mcp (0.0.76) is pinned against an older playwright-core
  # than the playwright-driver it runs against (1.61.x). 1.61.1 rejects the
  # --user-data-dir we need with "userDataDir is not supported in isolated
  # mode", crashing the server on startup. Fetching the package via npx makes it
  # bring its own matching playwright-core, sidestepping the skew. Pinned to a
  # known-good version for a bit of reproducibility; bump when needed. Downside:
  # not fully offline -> needs network on first run / npx cache miss. We still
  # point it at the Chromium from playwright-driver.browsers (read-only nix
  # store) via --executable-path so no browser download happens.
  #
  # The chromium-<rev> subdir version changes whenever nixpkgs bumps
  # playwright-driver, so resolve it with a glob at launch time rather than
  # hardcoding the revision (which used to go stale and silently break the
  # browser on every update). The store path itself stays nix-pinned; only the
  # version subdir is discovered. The glob matches chromium-<rev> but not
  # chromium_headless_shell-<rev>.
  playwrightMcpWrapped = pkgs.writeShellScriptBin "playwright-mcp-wrapped" ''
    set -euo pipefail
    export PATH=${lib.makeBinPath [pkgs.nodejs]}:$PATH
    shopt -s nullglob
    matches=(${pkgs.playwright-driver.browsers}/chromium-*/chrome-linux64/chrome)
    if [ ''${#matches[@]} -eq 0 ]; then
      echo "playwright-mcp: no chromium-* found in ${pkgs.playwright-driver.browsers}" >&2
      exit 1
    fi
    exec ${pkgs.nodejs}/bin/npx -y @playwright/mcp@0.0.78 \
      --browser chromium \
      --executable-path "''${matches[0]}" \
      --user-data-dir "${pwUserDataDir}" \
      "$@"
  '';

  gcloudMcp = pkgs.writeShellScriptBin "gcloud-mcp-wrapped" ''
    export PATH=${lib.makeBinPath [pkgs.nodejs pkgs.google-cloud-sdk]}:$PATH
    exec ${pkgs.nodejs}/bin/npx -y @google-cloud/gcloud-mcp "$@"
  '';

  # Community Gmail MCP server that talks to the plain Gmail REST API
  # (gmail.googleapis.com). We deliberately do NOT use Google's hosted
  # gmailmcp.googleapis.com endpoint: that gateway gates every tools/call behind
  # the cloud-platform scope + the mcp.tools.call IAM permission, and Google's
  # consent flow refuses to issue cloud-platform to an unverified OAuth client,
  # so tools/call always 403s ("caller does not have permission") even though
  # the same token works fine against the REST API. This server needs only
  # gmail.readonly/compose. GMAIL_OAUTH_PATH holds the OAuth *client* keys
  # (clientId/secret); GMAIL_CREDENTIALS_PATH holds the user refresh token
  # minted by the one-time `personal-gmail-mcp-wrapped auth` browser flow. The
  # fallbacks make that bootstrap runnable without exporting env by hand.
  personalGmailMcp = pkgs.writeShellScriptBin "personal-gmail-mcp-wrapped" ''
    export PATH=${lib.makeBinPath [pkgs.nodejs]}:$PATH
    export GMAIL_OAUTH_PATH="''${GMAIL_OAUTH_PATH:-/run/agenix/personal-gmail-oauth-keys}"
    export GMAIL_CREDENTIALS_PATH="''${GMAIL_CREDENTIALS_PATH:-${config.home.homeDirectory}/.gmail-mcp/credentials.json}"
    exec ${pkgs.nodejs}/bin/npx -y @gongrzhe/server-gmail-autoauth-mcp "$@"
  '';
in {
  home.packages = with pkgs; [
    # on PATH so the one-time OAuth bootstrap is just `personal-gmail-mcp-wrapped auth`
    personalGmailMcp
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
        gcloud = {
          command = "${gcloudMcp}/bin/gcloud-mcp-wrapped";
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
        # Kept in the nas1 block because it references the nas1-only agenix
        # secret below; move the secret to more hosts to widen availability.
        personal-gmail = {
          command = "${personalGmailMcp}/bin/personal-gmail-mcp-wrapped";
          env = {
            GMAIL_OAUTH_PATH = osConfig.age.secrets."personal-gmail-oauth-keys".path;
            GMAIL_CREDENTIALS_PATH = "${config.home.homeDirectory}/.gmail-mcp/credentials.json";
          };
        };
      };
  };
}
