{
  config,
  pkgs,
  ...
}: {
  age.secrets.dawarich_env.file = ../../secrets/dawarich_env.age;
  age.secrets.dawarich_db_env.file = ../../secrets/dawarich_db_env.age;

  # Dawarich location history: web app + sidekiq on the upstream image (the
  # nixpkgs module would need a PostGIS dump/restore), PostGIS 17, Valkey, and a
  # 1 req/s nginx throttle in front of nominatim.openstreetmap.org for reverse
  # geocoding. nginx fronts dawarich.gvarph.com -> :8090 (native OIDC).
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks;
    image = "docker.io/freikin/dawarich:1.15.2";
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/dawarich";
    };
    # App and sidekiq share public/, storage/ and watched/, so both run as root
    # inside like under compose; a shared private namespace would need a pod.
    appEnv = {
      RAILS_ENV = "production";
      REDIS_URL = "redis://dawarich-valkey:6379";
      DATABASE_HOST = "dawarich-db";
      DATABASE_PORT = "5432";
      DATABASE_USERNAME = "postgres";
      DATABASE_NAME = "dawarich_development";
      TIME_ZONE = "Europe/Prague";
      APPLICATION_PROTOCOL = "http";
      PROMETHEUS_EXPORTER_ENABLED = "true";
      RAILS_LOG_TO_STDOUT = "true";
      SELF_HOSTED = "true";
      STORE_GEODATA = "true";
      PHOTON_API_HOST = "";
      NOMINATIM_API_HOST = "geocoding-throttle:8080";
      NOMINATIM_API_USE_HTTPS = "false";
    };
    appVolumes = [
      "/flash/dawarich/public:/var/app/public"
      "/flash/dawarich/watched:/var/app/tmp/imports/watched"
      "/flash/dawarich/storage:/var/app/storage"
    ];
    throttleConf = pkgs.writeText "geocoding-throttle.conf" ''
      worker_processes 1;
      events { worker_connections 256; }
      http {
        access_log off;
        error_log /dev/stderr warn;
        # Nominatim's usage policy caps you at 1 req/s; exceeding it risks an IP block.
        limit_req_zone "global" zone=nominatim:1m rate=1r/s;
        limit_req_status 429;
        upstream nominatim_upstream {
          server nominatim.openstreetmap.org:443;
          keepalive 2;
        }
        server {
          listen 8080;
          location = /healthz {
            return 200 "ok\n";
            add_header Content-Type text/plain;
          }
          location / {
            limit_req zone=nominatim burst=3;
            proxy_pass https://nominatim_upstream;
            proxy_http_version 1.1;
            proxy_set_header Host nominatim.openstreetmap.org;
            proxy_set_header Connection "";
            proxy_ssl_server_name on;
            proxy_ssl_name nominatim.openstreetmap.org;
            proxy_set_header User-Agent $http_user_agent;
            proxy_connect_timeout 4s;
            proxy_read_timeout 4s;
          }
        }
      }
    '';
  in {
    networks.dawarich = {};

    containers.dawarich-valkey = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/valkey/valkey:8.1.10-alpine";
        exec = "valkey-server --save 900 1 --save 300 10 --appendonly no";
        networks = [networks.dawarich.ref];
        volumes = ["/flash/dawarich/shared:/data:U"];
        userns = "auto";
        noNewPrivileges = true;
        healthCmd = "valkey-cli --raw incr ping";
        healthInterval = "10s";
        healthTimeout = "10s";
        healthStartPeriod = "30s";
        healthRetries = 5;
        notify = "healthy";
      };
      serviceConfig.Restart = "always";
    };

    containers.dawarich-db = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/postgis/postgis:17-3.5-alpine";
        environmentFiles = [config.age.secrets.dawarich_db_env.path];
        networks = [networks.dawarich.ref];
        volumes = [
          "/flash/dawarich/db:/var/lib/postgresql/data:U"
          "/flash/dawarich/shared:/var/shared"
        ];
        shmSize = "1g";
        userns = "auto";
        noNewPrivileges = true;
        healthCmd = "pg_isready -U postgres -d dawarich_development";
        healthInterval = "10s";
        healthTimeout = "10s";
        healthStartPeriod = "30s";
        healthRetries = 5;
        notify = "healthy";
      };
      serviceConfig.Restart = "always";
    };

    containers.geocoding-throttle = {
      autoStart = true;
      containerConfig = {
        image = "docker.io/library/nginx:1.31.6-alpine";
        networks = [networks.dawarich.ref];
        volumes = ["${throttleConf}:/etc/nginx/nginx.conf:ro"];
        userns = "auto";
        noNewPrivileges = true;
        # 127.0.0.1, not localhost: busybox wget tries ::1 first and nginx is v4-only.
        healthCmd = "wget -qO- http://127.0.0.1:8080/healthz";
        healthInterval = "30s";
        healthTimeout = "5s";
        healthStartPeriod = "10s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.dawarich-app = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["dawarich-db.service" "dawarich-valkey.service"];
          Wants = ["dawarich-db.service" "dawarich-valkey.service"];
        };
      containerConfig = {
        inherit image;
        entrypoint = "web-entrypoint.sh";
        exec = "bin/rails server -p 3000 -b ::";
        environmentFiles = [config.age.secrets.dawarich_env.path];
        environments = appEnv // {ALLOW_EMAIL_PASSWORD_LOGIN = "false";};
        networks = [networks.dawarich.ref];
        publishPorts = ["127.0.0.1:8090:3000"];
        volumes = appVolumes ++ ["/flash/dawarich/db:/dawarich_db_data"];
        # Same resource caps as the compose stack.
        memory = "4g";
        podmanArgs = ["--cpus=0.5"];
        noNewPrivileges = true;
        healthCmd = "wget -qO - http://127.0.0.1:3000/api/v1/health | grep -q '\"status\"\\s*:\\s*\"ok\"'";
        healthInterval = "10s";
        healthTimeout = "10s";
        healthStartPeriod = "30s";
        healthRetries = 30;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.dawarich-sidekiq = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["dawarich-app.service"];
          Wants = ["dawarich-app.service"];
        };
      containerConfig = {
        inherit image;
        entrypoint = "sidekiq-entrypoint.sh";
        exec = "sidekiq";
        environmentFiles = [config.age.secrets.dawarich_env.path];
        environments = appEnv // {BACKGROUND_PROCESSING_CONCURRENCY = "5";};
        networks = [networks.dawarich.ref];
        volumes = appVolumes;
        noNewPrivileges = true;
        healthCmd = "pgrep -f sidekiq";
        healthInterval = "10s";
        healthTimeout = "10s";
        healthStartPeriod = "30s";
        healthRetries = 30;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services = {
    dawarich-db.restartTriggers = [config.age.secrets.dawarich_db_env.file];
    dawarich-app.restartTriggers = [config.age.secrets.dawarich_env.file];
    dawarich-sidekiq.restartTriggers = [config.age.secrets.dawarich_env.file];
  };
}
