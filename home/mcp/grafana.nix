{
  pkgs,
  lib,
  osConfig,
  ...
}: {
  # nas1 runs Grafana locally; this server is only useful while SSH'd into it.
  # Referencing osConfig.age.secrets.grafana_mcp_token (a nas1-only secret) is
  # safe because mkIf leaves the block unevaluated on every other host. uv/uvx
  # is pulled in via its store path so the dependency is visible only to this
  # server, not on the user's PATH.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    grafana = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["mcp-grafana"];
      env = {
        GRAFANA_URL = "http://localhost:3000";
        GRAFANA_SERVICE_ACCOUNT_TOKEN.file = osConfig.age.secrets.grafana_mcp_token.path;
      };
    };
  };
}
