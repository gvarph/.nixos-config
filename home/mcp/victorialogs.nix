{
  lib,
  osConfig,
  ...
}: {
  # Throwaway stdio container so nothing stays resident. VictoriaLogs is a
  # native service on loopback (devices/nas1/logs.nix), hence host networking.
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    victorialogs = {
      command = "/run/current-system/sw/bin/docker";
      args = [
        "run"
        "-i"
        "--rm"
        "--network"
        "host"
        "-e"
        "VL_INSTANCE_ENTRYPOINT=http://127.0.0.1:9428"
        "ghcr.io/victoriametrics/mcp-victorialogs:v1.9.0"
      ];
    };
  };
}
