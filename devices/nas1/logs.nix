{...}: {
  # Journal -> Fluent Bit -> VictoriaLogs, replacing the monitoring/logs compose
  # stack. State is the rpool/flash/victorialogs dataset mounted at the module's
  # DynamicUser path; logs are disposable, so it is kept out of sanoid, syncoid
  # and restic (see disko/sanoid.nix and restic.nix).
  services.victorialogs = {
    enable = true;
    # Loopback only; it has no auth and 9428 sits in the LAN-open port range.
    listenAddress = "127.0.0.1:9428";
    extraOptions = ["-retentionPeriod=30d"];
  };
  systemd.services.victorialogs = {
    after = ["zfs-mount.service"];
    # Never write into rpool/root if the dataset is missing.
    unitConfig.ConditionPathIsMountPoint = "/var/lib/private/victorialogs";
  };

  # Docker and podman both log to journald, so one systemd input covers host
  # units and every container.
  services.fluent-bit = {
    enable = true;
    settings = {
      service = {
        flush = 5;
        log_level = "info";
        http_server = "on";
        http_listen = "127.0.0.1";
        http_port = 2020;
        health_check = "on";
      };
      pipeline = {
        inputs = [
          {
            name = "systemd";
            tag = "journal.*";
            path = "/var/log/journal";
            read_from_tail = "on";
            strip_underscores = "on";
          }
        ];
        # VictoriaLogs native JSON-line insert; _stream_fields key the streams.
        outputs = [
          {
            name = "http";
            match = "*";
            host = "127.0.0.1";
            port = 9428;
            uri = "/insert/jsonline?_stream_fields=CONTAINER_NAME,SYSTEMD_UNIT,HOSTNAME&_msg_field=MESSAGE&_time_field=date";
            format = "json_lines";
            json_date_key = "date";
            json_date_format = "iso8601";
            compress = "gzip";
          }
        ];
      };
    };
  };
  systemd.services.fluent-bit.after = ["victorialogs.service"];
}
