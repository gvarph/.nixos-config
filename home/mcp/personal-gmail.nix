{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: let
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
  # on PATH so the one-time OAuth bootstrap is just `personal-gmail-mcp-wrapped auth`
  home.packages = [personalGmailMcp];

  # Enabled only on nas1 because it references the nas1-only agenix secret;
  # move the secret to more hosts to widen availability. mkIf keeps the
  # secret-path reference unevaluated on every other host.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    personal-gmail = {
      command = "${personalGmailMcp}/bin/personal-gmail-mcp-wrapped";
      env = {
        GMAIL_OAUTH_PATH = osConfig.age.secrets."personal-gmail-oauth-keys".path;
        GMAIL_CREDENTIALS_PATH = "${config.home.homeDirectory}/.gmail-mcp/credentials.json";
      };
    };
  };
}
