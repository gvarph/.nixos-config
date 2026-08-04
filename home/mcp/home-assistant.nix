{
  lib,
  osConfig,
  ...
}: {
  # Throwaway stdio container so nothing stays resident; joins metrics_metrics to
  # reach VictoriaLogs by container DNS. No auth on the instance.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    home-assistant = {
      type = "http";
      url = "https://ha.gvarph.com/api/mcp";
    };
  };
}
