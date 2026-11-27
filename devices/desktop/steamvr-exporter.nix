{username}: {
  config,
  lib,
  pkgs,
  ...
}: {
  # SteamVR frame timing + Steam Link stream health, pushed to VictoriaMetrics
  # on nas1 through metrics.gvarph.com (LAN-only, basic auth). A user unit:
  # it talks to the user's SteamVR session and tails the user's Steam logs.
  age.secrets.vm_push_auth = {
    file = ../../secrets/vm_push_auth.age;
    owner = username;
  };

  systemd.user.services.steamvr-exporter = {
    description = "Push SteamVR frame metrics to VictoriaMetrics";
    wantedBy = ["default.target"];
    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        (lib.getExe pkgs.steamvr-exporter)
        "--url=https://metrics.gvarph.com/api/v1/import/prometheus"
        "--auth-file=${config.age.secrets.vm_push_auth.path}"
        "--instance=${config.networking.hostName}"
      ];
      Restart = "always";
      RestartSec = 10;
    };
  };
}
