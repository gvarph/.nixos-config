{
  config,
  lib,
  pkgs,
  ...
}: let
  cloudflareRanges = import ./cloudflare-ips.nix;

  # Docker logs to journald. `-o cat` drops the syslog prefix so the label
  # names the program each hub parser filters on (same shape as the docker source).
  # Keys are the program names the parsers expect; values are container names.
  containerLogs = {
    jellyfin = "jellyfin";
    jellyseerr = "jellyseerr";
    immich = "immich-server";
    paperless-ngx = "paperless";
    grafana = "grafana";
  };
  containerAcquisitions =
    lib.mapAttrsToList (program: container: {
      source = "journalctl";
      journalctl_filter = ["-o" "cat" "CONTAINER_NAME=${container}"];
      labels.type = program;
    })
    containerLogs;
in {
  services.crowdsec = {
    enable = true;
    autoUpdateService = true;
    hub.collections = [
      # syslog/sshd parsers + ssh-bf; nginx-logs + base-http-scenarios + http-cve.
      "crowdsecurity/linux"
      "crowdsecurity/nginx"
      # Per-app login brute-force detection, one collection per containerLogs entry.
      "LePresidente/jellyfin"
      "LePresidente/jellyseerr"
      "gauth-fr/immich"
      "plague-doctor/audiobookshelf"
      "andreasbrett/paperless-ngx"
      "LePresidente/grafana"
      "sdwilsh/navidrome"
      "Jgigantino31/ntfy"
    ];

    settings = {
      # The module ships with the LAPI off and no credentials path; both are
      # required for a standalone engine. 8080 is taken by qbittorrent.
      general.api.server = {
        enable = true;
        listen_uri = "127.0.0.1:8082";
      };
      lapi.credentialsFile = "/var/lib/crowdsec/lapi.yaml";
      # Setting this makes the module run `cscli capi register` on first start:
      # community blocklist pulled in, local alerts shared back.
      capi.credentialsFile = "/var/lib/crowdsec/capi.yaml";
      # Immich/Jellyfin clients on mobile networks burst non-static API calls
      # and trip this scenario, so log it without enforcing.
      simulation = {
        simulation = false;
        exclusions = ["crowdsecurity/http-crawl-non_statics"];
      };
    };

    localConfig = {
      # journalctl output is syslog-shaped, so those sources go through the
      # syslog parser first; the access log is a plain file in combined format.
      acquisitions =
        [
          {
            source = "file";
            filenames = ["/var/log/nginx/access.log"];
            labels.type = "nginx";
          }
          {
            source = "journalctl";
            journalctl_filter = ["_SYSTEMD_UNIT=nginx.service"];
            labels.type = "syslog";
          }
          {
            source = "journalctl";
            journalctl_filter = ["_SYSTEMD_UNIT=sshd.service"];
            labels.type = "syslog";
          }
          # Native ntfy logs JSON to the journal; the parser matches program 'ntfy'.
          {
            source = "journalctl";
            journalctl_filter = ["-o" "cat" "_SYSTEMD_UNIT=ntfy-sh.service"];
            labels.type = "ntfy";
          }
          {
            source = "journalctl";
            journalctl_filter = ["-o" "cat" "_SYSTEMD_UNIT=navidrome.service"];
            labels.type = "navidrome";
          }
          # ABS's stdout is plain text, which its hub parser JSON-decodes with an
          # error per line; the daily files in its metadata volume are JSON lines.
          {
            source = "file";
            filenames = ["/flash/audiobookshelf/metadata/logs/daily/*.txt"];
            labels.type = "audiobookshelf";
          }
        ]
        ++ containerAcquisitions;

      # LAN VLANs and docker bridges: never ban ourselves or our own containers.
      # Cloudflare edges are a safety net in case nginx real_ip ever misses one.
      parsers.s02Enrich = [
        {
          name = "gvarph/whitelist";
          description = "LAN, docker bridges, Cloudflare edges";
          whitelist = {
            reason = "own networks and Cloudflare edges";
            cidr = ["10.0.0.0/8" "172.16.0.0/12"] ++ cloudflareRanges;
          };
        }
      ];

      # 4h for a first offense, +4h per prior decision, capped at 48h
      # (fail2ban's bantime-increment equivalent).
      profiles = [
        {
          name = "default_ip_remediation";
          filters = ["Alert.Remediation == true && Alert.GetScope() == 'Ip'"];
          decisions = [
            {
              type = "ban";
              duration = "4h";
            }
          ];
          duration_expr = "(GetDecisionsCount(Alert.GetValue()) + 1) * 4 > 48 ? '48h' : Sprintf('%dh', (GetDecisionsCount(Alert.GetValue()) + 1) * 4)";
          on_success = "break";
        }
        {
          name = "default_range_remediation";
          filters = ["Alert.Remediation == true && Alert.GetScope() == 'Range'"];
          decisions = [
            {
              type = "ban";
              duration = "4h";
            }
          ];
          on_success = "break";
        }
      ];
    };
  };

  # /var/log/nginx is 0750 nginx:nginx; the module only grants systemd-journal.
  users.users.crowdsec.extraGroups = ["nginx"];

  # Registers itself against the local LAPI; iptables mode since nftables is off.
  services.crowdsec-firewall-bouncer.enable = true;

  # Upstream module workarounds (nixpkgs as of 2026-09):
  # The setup script runs `machines add` before `capi register`, and the former
  # refuses to start if the CAPI file is missing; an empty one loads with a warning.
  systemd.tmpfiles.settings."10-crowdsec"."/var/lib/crowdsec/capi.yaml".f = {
    user = "crowdsec";
    group = "crowdsec";
    mode = "0600";
  };
  # The register unit calls the bare cscli, which only looks here for its config.
  environment.etc."crowdsec/config.yaml".source =
    (pkgs.formats.yaml {}).generate "crowdsec.yaml" config.services.crowdsec.settings.general;
  # With DynamicUser the register unit moves /var/lib/crowdsec under the root-only
  # /var/lib/private, which the engine and the cscli wrapper cannot traverse.
  systemd.services.crowdsec-firewall-bouncer-register.serviceConfig.DynamicUser = lib.mkForce false;
  # The bouncer only `requires` its register unit; without `after` it loads the
  # API key credential before the key has been written.
  systemd.services.crowdsec-firewall-bouncer.after = ["crowdsec-firewall-bouncer-register.service"];
}
