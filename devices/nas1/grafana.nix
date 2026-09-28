{config, ...}: {
  # Both read by grafana itself via $__file{}, so they must be grafana-readable.
  age.secrets.ntfy_grafana_token = {
    file = ../../secrets/ntfy_grafana_token.age;
    owner = "grafana";
  };
  age.secrets.grafana_secret_key = {
    file = ../../secrets/grafana_secret_key.age;
    owner = "grafana";
  };

  # Replaces the grafana/grafana container. nginx keeps proxying
  # grafana.gvarph.com to localhost:3000. State (grafana.db with users and the
  # MCP service account) is the rpool/flash/grafana dataset at /var/lib/grafana.
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://grafana.gvarph.com/";
      };
      # New key: whatever the carried-over grafana.db encrypted with the docker
      # image's default key is unreadable now (datasources have no credentials).
      security.secret_key = "$__file{${config.age.secrets.grafana_secret_key.path}}";
      users.allow_sign_up = false;
      auth.oauth_allow_insecure_email_lookup = true;
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };

    provision = {
      datasources.settings = {
        # Recreate by name: changing a persisted datasource's uid in place fails.
        deleteDatasources = [
          {
            # Compose-era leftover pointing at the docker0 gateway.
            name = "prometheus";
            orgId = 1;
          }
          {
            name = "Victoria Metrics";
            orgId = 1;
          }
          {
            name = "Victoria Logs";
            orgId = 1;
          }
        ];
        datasources = [
          {
            name = "Victoria Metrics";
            type = "prometheus";
            uid = "victoriametrics";
            access = "proxy";
            url = "http://127.0.0.1:8428";
            isDefault = true;
            editable = true;
            jsonData.timeInterval = "15s";
          }
          {
            name = "Victoria Logs";
            type = "loki";
            uid = "victorialogs";
            access = "proxy";
            url = "http://127.0.0.1:9428";
            editable = true;
            jsonData.maxLines = 1000;
          }
        ];
      };

      dashboards.settings.providers = [
        {
          name = "Default";
          orgId = 1;
          folder = "";
          type = "file";
          disableDeletion = false;
          allowUiUpdates = true;
          options.path = ./grafana/dashboards;
        }
      ];

      alerting = {
        contactPoints.settings.contactPoints = [
          {
            orgId = 1;
            name = "ntfy";
            receivers = [
              {
                uid = "ntfy-alerts";
                type = "webhook";
                settings = {
                  url = "http://127.0.0.1:8091/";
                  httpMethod = "POST";
                  authorization_scheme = "Bearer";
                  authorization_credentials = "$__file{${config.age.secrets.ntfy_grafana_token.path}}";
                  # Grafana expands $VAR in this file, so template $ is written $$.
                  # No {{ define }}: templates defined in the payload can't be Exec'd.
                  payload.template = ''
                    {{- $$msg := "" -}}
                    {{- range .Alerts.Firing }}{{ $$msg = print $$msg "FIRING: " .Labels.alertname " - " .Annotations.summary "\n" }}{{ end -}}
                    {{- range .Alerts.Resolved }}{{ $$msg = print $$msg "RESOLVED: " .Labels.alertname " - " .Annotations.summary "\n" }}{{ end -}}
                    {{- if .Alerts.Firing -}}
                    {{ coll.Dict "topic" "alerts" "title" (print "Grafana: " (len .Alerts.Firing) " alert(s) firing") "message" $$msg "priority" 4 "tags" (coll.Slice "rotating_light") | data.ToJSON }}
                    {{- else -}}
                    {{ coll.Dict "topic" "alerts" "title" "Grafana: alerts resolved" "message" $$msg "priority" 3 "tags" (coll.Slice "white_check_mark") | data.ToJSON }}
                    {{- end }}'';
                };
              }
            ];
          }
        ];

        policies.settings.policies = [
          {
            orgId = 1;
            receiver = "ntfy";
            group_by = ["grafana_folder" "alertname"];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "4h";
          }
        ];

        # Rule files are not env-expanded, so template $ stays a single $.
        rules.settings.groups = let
          threshold = op: value: {
            refId = "C";
            relativeTimeRange = {
              from = 0;
              to = 0;
            };
            datasourceUid = "__expr__";
            model = {
              refId = "C";
              type = "threshold";
              expression = "A";
              conditions = [
                {
                  evaluator = {
                    type = op;
                    params = [value];
                  };
                }
              ];
            };
          };
          query = expr: {
            refId = "A";
            relativeTimeRange = {
              from = 600;
              to = 0;
            };
            datasourceUid = "victoriametrics";
            model = {
              refId = "A";
              instant = true;
              range = false;
              inherit expr;
            };
          };
          fs = ''{fstype!~"tmpfs|ramfs|overlay|squashfs|iso9660"}'';
        in [
          {
            orgId = 1;
            name = "homelab";
            folder = "Homelab";
            interval = "1m";
            rules = [
              {
                uid = "disk-space-low";
                title = "Disk space low";
                condition = "C";
                for = "10m";
                noDataState = "NoData";
                execErrState = "Error";
                labels.severity = "warning";
                annotations.summary = ''{{ $labels.instance }} {{ $labels.mountpoint }} has {{ printf "%.1f" $values.A.Value }}% free'';
                data = [
                  (query "100 * node_filesystem_avail_bytes${fs} / node_filesystem_size_bytes${fs}")
                  (threshold "lt" 10)
                ];
              }
              {
                uid = "smart-health-failing";
                title = "SMART health failing";
                condition = "C";
                for = "5m";
                noDataState = "NoData";
                execErrState = "Error";
                labels.severity = "critical";
                annotations.summary = "SMART status not OK for {{ $labels.device }} on {{ $labels.instance }}";
                data = [
                  (query "smartctl_device_smart_status")
                  (threshold "lt" 1)
                ];
              }
              {
                # Targets are static now, so a stopped exporter reports up == 0
                # instead of vanishing like it did under docker_sd.
                uid = "scrape-target-down";
                title = "Scrape target not responding";
                condition = "C";
                for = "5m";
                noDataState = "OK";
                execErrState = "Error";
                labels.severity = "warning";
                annotations.summary = "{{ $labels.job }} ({{ $labels.instance }}) is failing scrapes";
                data = [
                  (query "up")
                  (threshold "lt" 1)
                ];
              }
              {
                uid = "host-memory-low";
                title = "Host memory low";
                condition = "C";
                for = "10m";
                noDataState = "NoData";
                execErrState = "Error";
                labels.severity = "warning";
                annotations.summary = ''Host has {{ printf "%.1f" $values.A.Value }}% memory available'';
                data = [
                  (query "100 * node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes")
                  (threshold "lt" 5)
                ];
              }
            ];
          }
        ];
      };
    };
  };

  systemd.services.grafana = {
    after = ["zfs-mount.service"];
    # Never write into rpool/root if the dataset is missing.
    unitConfig.ConditionPathIsMountPoint = "/var/lib/grafana";
    restartTriggers = [
      config.age.secrets.ntfy_grafana_token.file
      config.age.secrets.grafana_secret_key.file
    ];
  };
}
