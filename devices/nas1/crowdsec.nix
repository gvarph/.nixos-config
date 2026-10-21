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
  };
  containerAcquisitions =
    lib.mapAttrsToList (program: container: {
      source = "journalctl";
      journalctl_filter = ["-o" "cat" "CONTAINER_NAME=${container}"];
      labels.type = program;
    })
    containerLogs;
in {
  age.secrets.crowdsec_ntfy_env.file = ../../secrets/crowdsec_ntfy_env.age;
  age.secrets.crowdsec_nginx_bouncer_key.file = ../../secrets/crowdsec_nginx_bouncer_key.age;
  age.secrets.vl_push_htpasswd = {
    file = ../../secrets/vl_push_htpasswd.age;
    owner = "nginx";
  };

  # nginx Lua bouncer (nginx.nix): registered as a LAPI bouncer with our own
  # key, and its config rendered into nginx's runtime dir with the key filled
  # in before nginx's config test runs init_by_lua.
  systemd.services.crowdsec-nginx-bouncer-register = {
    after = ["crowdsec.service"];
    requires = ["crowdsec.service"];
    path = [config.services.crowdsec.package];
    serviceConfig.Type = "oneshot";
    script = ''
      key=$(cat ${config.age.secrets.crowdsec_nginx_bouncer_key.path})
      for i in 1 2 3 4 5 6; do
        cscli bouncers delete crowdsec-nginx --ignore-missing >/dev/null 2>&1 || true
        cscli bouncers add crowdsec-nginx --key "$key" >/dev/null && exit 0
        sleep 5
      done
      exit 1
    '';
  };
  systemd.services.nginx = let
    bouncerConf = pkgs.writeText "crowdsec-nginx-bouncer.conf" ''
      ENABLED=true
      API_URL=http://127.0.0.1:8082
      API_KEY=@API_KEY@
      USE_TLS_AUTH=false
      CACHE_EXPIRATION=1
      BOUNCING_ON_TYPE=all
      FALLBACK_REMEDIATION=ban
      REQUEST_TIMEOUT=3000
      UPDATE_FREQUENCY=10
      ENABLE_INTERNAL=false
      MODE=stream
      SCENARIOS_CONTAINING=
      SCENARIOS_NOT_CONTAINING=
      EXCLUDE_LOCATION=
      BAN_TEMPLATE_PATH=${pkgs.crowdsec-lua-bouncer}/share/crowdsec-lua-bouncer/templates/ban.html
      REDIRECT_LOCATION=
      RET_CODE=
      CAPTCHA_PROVIDER=
      SECRET_KEY=
      SITE_KEY=
      CAPTCHA_TEMPLATE_PATH=${pkgs.crowdsec-lua-bouncer}/share/crowdsec-lua-bouncer/templates/captcha.html
      CAPTCHA_EXPIRATION=3600
      APPSEC_URL=
      APPSEC_FAILURE_ACTION=passthrough
      ALWAYS_SEND_TO_APPSEC=false
      APPSEC_DROP_UNREADABLE_BODY=false
      SSL_VERIFY=true
    '';
    render = pkgs.writeShellScript "render-crowdsec-nginx-bouncer-conf" ''
      umask 077
      sed "s|@API_KEY@|$(cat ${config.age.secrets.crowdsec_nginx_bouncer_key.path})|" ${bouncerConf} > /run/nginx/crowdsec-bouncer.conf
      chown nginx:nginx /run/nginx/crowdsec-bouncer.conf
    '';
  in {
    after = ["crowdsec-nginx-bouncer-register.service"];
    wants = ["crowdsec-nginx-bouncer-register.service"];
    # Root (+) and before the module's own pre-start, whose `nginx -t` already runs init_by_lua.
    serviceConfig.ExecStartPre = lib.mkBefore ["+${render}"];
    restartTriggers = [config.age.secrets.crowdsec_nginx_bouncer_key.file bouncerConf];
  };
  systemd.services.crowdsec = {
    serviceConfig.EnvironmentFile = [config.age.secrets.crowdsec_ntfy_env.path];
    # Config files are linked in by tmpfiles, not referenced by the unit,
    # so a change would otherwise leave the running engine on the old ones.
    restartTriggers = [
      config.age.secrets.crowdsec_ntfy_env.file
      (builtins.toJSON config.services.crowdsec.settings)
    ];
  };
  # The module only adds links; stale ones from earlier generations would be
  # loaded too (duplicate plugin names). Wipe the dir before it is repopulated.
  systemd.tmpfiles.settings."10-crowdsec"."/etc/crowdsec/notifications/".R = {};
  # Leftover link from the pre-rewrite module (duplicate gvarph/whitelist).
  systemd.tmpfiles.settings."10-crowdsec"."/etc/crowdsec/parsers/s02-enrich/*-parsers-s02-enrich.yaml".r = {};

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
      # Home Assistant runs on another host; its journal arrives via
      # logs.gvarph.com into VictoriaLogs and is read back from there.
      "crowdsecurity/home-assistant"
    ];

    settings = {
      # The module ships with the LAPI off and no credentials path; both are
      # required for a standalone engine. 8080 is taken by qbittorrent.
      # Empty = plugins inherit the engine's user instead of a setuid/setgid
      # that older unit SystemCallFilters killed with SIGSYS.
      config.plugin_config = {
        user = "";
        group = "";
      };
      # State from before the 2026-10 module rewrite (db, hub, credentials).
      config.config_paths.data_dir = "/var/lib/crowdsec/state";
      config.api.client.credentials_path = "/var/lib/crowdsec/lapi.yaml";
      config.api.server.listen_uri = "127.0.0.1:8082";
      # Setting this makes the module run `cscli capi register` on first start:
      # community blocklist pulled in, local alerts shared back.
      config.api.server.online_client.credentials_path = "/var/lib/crowdsec/capi.yaml";
      # Immich/Jellyfin clients on mobile networks burst non-static API calls
      # and trip this scenario, so log it without enforcing.
      simulation = {
        simulation = false;
        exclusions = ["crowdsecurity/http-crawl-non_statics"];
      };

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
          {
            source = "journalctl";
            journalctl_filter = ["-o" "cat" "_SYSTEMD_UNIT=grafana.service"];
            labels.type = "grafana";
          }
          # Home Assistant core (container "homeassistant" on HAOS), tailed from
          # VictoriaLogs where its Vector add-on ships the journal with journald
          # field names as stream fields; the parser matches program home-assistant.
          {
            source = "victorialogs";
            url = "http://127.0.0.1:9428";
            query = ''{host="homeassistant",CONTAINER_NAME="homeassistant"}'';
            since = "5m";
            labels.type = "home-assistant";
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
      # Local decisions -> ntfy topic "crowdsec" (own topic so it can be muted;
      # the grafana user's token, granted write-only on it), batched over 10
      # minutes at low priority. The token is a ${NTFY_TOKEN} placeholder:
      # crowdsec expands env vars in plugin configs from the unit's EnvironmentFile.
      notifications = [
        {
          type = "http";
          name = "ntfy";
          log_level = "info";
          group_wait = "10m";
          url = "http://127.0.0.1:8091/crowdsec";
          method = "POST";
          headers = {
            Authorization = "Bearer \${NTFY_TOKEN}";
            Title = "CrowdSec";
            Tags = "shield";
            Priority = "low";
          };
          format = ''
            {{range . -}}
            {{$a := . -}}
            {{range .Decisions -}}
            {{.Value}} banned {{.Duration}}: {{.Scenario}}{{if $a.Source.Cn}} ({{$a.Source.Cn}}{{if $a.Source.AsName}}, {{$a.Source.AsName}}{{end}}){{end}}
            {{end -}}
            {{end -}}
          '';
        }
      ];

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
          # No Sprintf: the module writes this file through tmpfiles, where % is a specifier.
          duration_expr = "(GetDecisionsCount(Alert.GetValue()) + 1) * 4 > 48 ? '48h' : string((GetDecisionsCount(Alert.GetValue()) + 1) * 4) + 'h'";
          notifications = ["ntfy"];
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
          notifications = ["ntfy"];
          on_success = "break";
        }
      ];
    };
  };

  # /var/log/nginx is 0750 nginx:nginx; the module only grants systemd-journal.
  services.crowdsec.extraGroups = ["nginx"];

  # Registers itself against the local LAPI; iptables mode since nftables is off.
  services.crowdsec-firewall-bouncer.enable = true;

  # The bouncer only `requires` its register unit; without `after` it loads the
  # API key credential before the key has been written.
  systemd.services.crowdsec-firewall-bouncer = {
    after = ["crowdsec-firewall-bouncer-register.service"];
    # crowdsec signals ready before the LAPI listens, so retry instead of dying at boot.
    startLimitIntervalSec = 0;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
