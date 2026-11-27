# Host metrics pushed to VictoriaMetrics on nas1: vmagent scrapes a loopback
# node exporter and remote-writes through metrics.gvarph.com (LAN-only, basic
# auth as the host's name), so nas1 never scrapes this host and nothing new
# listens on the LAN. vmagent buffers on disk while nas1 is unreachable.
# Labels match nas1's own node exporter job so its dashboards pick it up.
# Each host needs secrets/vm_push_password_<hostname>.age and a matching
# entry in vm_push_htpasswd.age.
{
  collectors ? [],
  port ? 9100,
}: {config, ...}: let
  host = config.networking.hostName;
in {
  age.secrets.vm_push_password.file = ../secrets + "/vm_push_password_${host}.age";

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    inherit port;
    enabledCollectors = ["systemd"] ++ collectors;
    extraFlags = [
      # Removable media would trip nas1's disk-space alert when full.
      "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run/media/.+|run/user/.+|run/credentials/.+|var/lib/docker/.+|var/lib/kubelet/.+|run/k3s/.+)($|/)"
    ];
  };

  services.vmagent = {
    enable = true;
    remoteWrite = {
      url = "https://metrics.gvarph.com/api/v1/write";
      basicAuthUsername = host;
      basicAuthPasswordFile = config.age.secrets.vm_push_password.path;
    };
    extraArgs = ["-httpListenAddr=127.0.0.1:8429"];
    prometheusConfig = {
      global.scrape_interval = "30s";
      scrape_configs = [
        {
          job_name = "node-exporter";
          static_configs = [
            {
              targets = ["127.0.0.1:${toString port}"];
              labels = {
                job = "node-exporter";
                instance = host;
              };
            }
          ];
        }
      ];
    };
  };
}
