{
  lib,
  osConfig,
  ...
}: {
  # Throwaway stdio container so nothing stays resident; joins metrics_metrics to
  # reach VictoriaLogs by container DNS. No auth on the instance.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    victorialogs = {
      command = "/run/current-system/sw/bin/docker";
      args = [
        "run"
        "-i"
        "--rm"
        "--network"
        "metrics_metrics"
        "-e"
        "VL_INSTANCE_ENTRYPOINT=http://victoria-logs:9428"
        "ghcr.io/victoriametrics/mcp-victorialogs:v1.9.0"
      ];
    };
  };
}
