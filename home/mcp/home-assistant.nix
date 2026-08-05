{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  # `headers` values in mcp.json support only `${VAR}` environment expansion --
  # not the `${file:...}` form that `env` accepts -- so the token has to be in
  # claude's own environment. Wrap the binary instead of exporting it from the
  # shell profile so the token is scoped to the one process that needs it.
  # The secret is stored without a trailing newline; `$(cat ...)` strips any
  # that a future `agenix -e` round-trip introduces.
  claudeWithHaToken = pkgs.symlinkJoin {
    name = "claude-code-${pkgs.claude-code.version}";
    inherit (pkgs.claude-code) version;
    paths = [pkgs.claude-code];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/claude \
        --run 'export HA_MCP_TOKEN="$(cat ${osConfig.age.secrets.ha_mcp_token.path} 2>/dev/null)"'
    '';
  };
in {
  # HA's OAuth cannot be used here. It advertises
  # client_id_metadata_document_supported but never fetches the JSON document
  # (see the comment at homeassistant/components/auth/login_flow.py); validation
  # falls through to IndieAuth, which parses the client_id URL as HTML looking
  # for <link rel="redirect_uri"> tags. Claude's client_id serves JSON, so the
  # discovered list is always empty and every callback is rejected with
  # 403 "Invalid redirect URI" after login. A long-lived token is the only
  # working option, and it also avoids the loopback-callback problem when
  # running claude over SSH.
  config = lib.mkIf (osConfig.networking.hostName == "nas1") {
    programs.claude-code.package = claudeWithHaToken;

    programs.mcp.servers.home-assistant = {
      type = "http";
      url = "https://ha.gvarph.com/api/mcp";
      headers.Authorization = "Bearer \${HA_MCP_TOKEN}";
    };
  };
}
