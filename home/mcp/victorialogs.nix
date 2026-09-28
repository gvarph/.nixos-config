{
  pkgs,
  lib,
  osConfig,
  ...
}: {
  # Built from the pinned upstream tag (overlays/mcp-servers.nix); the earlier
  # `docker run` variant left a container behind whenever a session died.
  # VictoriaLogs is a native service on loopback (devices/nas1/logs.nix).
  programs.mcp.servers = lib.mkIf (osConfig.networking.hostName == "nas1") {
    victorialogs = {
      command = lib.getExe pkgs.mcp-victorialogs;
      env.VL_INSTANCE_ENTRYPOINT = "http://127.0.0.1:9428";
    };
  };
}
