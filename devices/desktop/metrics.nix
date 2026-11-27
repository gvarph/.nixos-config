{config, ...}: {
  # Host metrics pushed to VictoriaMetrics on nas1: vmagent scrapes the local
  # node exporter and remote-writes through metrics.gvarph.com (LAN-only,
  # basic auth), so nas1 never scrapes the desktop and nothing listens on
  # the LAN here. vmagent buffers on disk while nas1 is unreachable.
  # Labels match nas1's own node exporter job so its dashboards pick it up.
  age.secrets.vm_push_password.file = ../../secrets/vm_push_password.age;

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    # drm: amdgpu busy % and VRAM; wifi: per-station signal, bitrate and
    # retries, which covers the Steam Frame wireless adapter's link.
    enabledCollectors = ["systemd" "drm" "wifi"];
    extraFlags = [
      # Removable media would trip nas1's disk-space alert when full.
      "--collector.filesystem.mount-points-exclude=^/(dev|proc|sys|run/media/.+|run/user/.+|run/credentials/.+|var/lib/docker/.+)($|/)"
    ];
  };

  services.vmagent = {
    enable = true;
    remoteWrite = {
      url = "https://metrics.gvarph.com/api/v1/write";
      basicAuthUsername = "desktop";
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
              targets = ["127.0.0.1:9100"];
              labels = {
                job = "node-exporter";
                instance = config.networking.hostName;
              };
            }
          ];
        }
      ];
    };
  };
}
