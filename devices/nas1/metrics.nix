{config, ...}: let
  # Static scrape targets replace the compose stack's docker_sd; job and
  # instance keep the old container names so the provisioned dashboards match.
  targets = [
    {
      job = "victoriametrics";
      target = "127.0.0.1:8428";
    }
    {
      job = "vmagent";
      target = "127.0.0.1:8429";
    }
    {
      job = "cadvisor";
      target = "127.0.0.1:18080";
    }
    {
      job = "node-exporter";
      target = "127.0.0.1:9100";
    }
    {
      job = "smartctl-exporter";
      target = "127.0.0.1:9633";
    }
    {
      job = "grafana";
      target = "127.0.0.1:3000";
    }
    {
      job = "victorialogs";
      target = "127.0.0.1:9428";
    }
    {
      job = "fluent-bit";
      target = "127.0.0.1:2020";
      path = "/api/v2/metrics/prometheus";
    }
    {
      job = "ntfy";
      target = "127.0.0.1:8091";
    }
    {
      job = "immich-api";
      target = "127.0.0.1:18081";
    }
    {
      job = "immich-microservices";
      target = "127.0.0.1:18082";
    }
    # Sidecars from db-exporters.nix; instance names the database container.
    {
      job = "postgres-exporter";
      instance = "immich-database";
      target = "127.0.0.1:9187";
    }
    {
      job = "postgres-exporter";
      instance = "paperless-db";
      target = "127.0.0.1:9188";
    }
    {
      job = "postgres-exporter";
      instance = "sparkyfitness-db";
      target = "127.0.0.1:9189";
    }
    {
      job = "postgres-exporter";
      instance = "jellystat-db";
      target = "127.0.0.1:9190";
    }
    {
      job = "redis-exporter";
      instance = "immich-redis";
      target = "127.0.0.1:9121";
    }
    {
      job = "redis-exporter";
      instance = "paperless-broker";
      target = "127.0.0.1:9122";
    }
  ];
in {
  # Metrics store. State is the rpool/flash/victoriametrics dataset mounted at
  # the module's DynamicUser path; like victorialogs it is kept out of sanoid,
  # syncoid and restic (30 days of samples are not worth replicating).
  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "1"; # months, same as the compose default
  };
  systemd.services.victoriametrics = {
    after = ["zfs-mount.service"];
    # Never write into rpool/root if the dataset is missing.
    unitConfig.ConditionPathIsMountPoint = "/var/lib/private/victoriametrics";
  };

  services.vmagent = {
    enable = true;
    remoteWrite.url = "http://127.0.0.1:8428/api/v1/write";
    extraArgs = ["-httpListenAddr=127.0.0.1:8429"];
    prometheusConfig = {
      global.scrape_interval = "30s";
      scrape_configs = map (t:
        {
          job_name =
            t.job
            + (
              if t ? instance
              then "/" + t.instance
              else ""
            );
          static_configs = [
            {
              targets = [t.target];
              labels = {
                job = t.job;
                instance = t.instance or t.job;
              };
            }
          ];
        }
        // (
          if t ? path
          then {metrics_path = t.path;}
          else {}
        )
        // (
          if t.job == "cadvisor"
          then {
            # Raw cgroup ids -> `unit` for every service and `name` for the
            # container payloads, which is what the container dashboards key on.
            metric_relabel_configs = [
              {
                source_labels = ["id"];
                regex = "/system\\.slice/([^/]+)\\.service(/.*)?";
                target_label = "unit";
                replacement = "$1";
              }
              {
                source_labels = ["id"];
                regex = "/system\\.slice/([^/]+)\\.service/libpod-payload-.*";
                target_label = "name";
                replacement = "$1";
              }
            ];
          }
          else {}
        ))
      targets;
    };
  };
  systemd.services.vmagent.after = ["victoriametrics.service"];

  # Per-cgroup CPU/memory/network for everything under system.slice: native
  # services and the quadlets' libpod-payload cgroups (vmagent turns those into
  # a `name` label above). cadvisor's podman factory expects libpod-<id>.scope
  # cgroups and fails on quadlet's split layout, so it is pointed at a dead
  # socket. The compose setup (1s-10s housekeeping, every metric group, labels)
  # was the resource hog that got monitoring switched off; this is the minimum.
  services.cadvisor = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 18080; # 8080 is qbittorrent
    extraOptions = [
      "-podman=unix:///run/podman/cadvisor-disabled.sock"
      "-docker_only=true"
      "-raw_cgroup_prefix_whitelist=/system.slice/"
      "-housekeeping_interval=30s"
      "-max_housekeeping_interval=2m"
      "-enable_metrics=cpu,memory,network,oom_event"
      "-store_container_labels=false"
    ];
  };

  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    # zfs is on by default; systemd adds unit states for the quadlets.
    enabledCollectors = ["systemd"];
  };

  # Auto-scans the four HDDs and the NVMe; the module grants the raw-IO caps.
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9633;
  };
  # The module's NVMe access is an ACL set by a udev rule on device add, i.e.
  # at boot only; replay it (as root) so a restart never races the descriptors.
  systemd.services.prometheus-smartctl-exporter.serviceConfig.ExecStartPre = [
    "+${config.systemd.package}/bin/udevadm trigger --subsystem-match=nvme --action=add --settle"
  ];
}
