{config, ...}: {
  age.secrets.immich_env.file = ../../secrets/immich_env.age;
  age.secrets.immich_db_env.file = ../../secrets/immich_db_env.age;

  # Immich with Intel QSV transcoding and OpenVINO machine learning on the iGPU.
  # nginx fronts immich.gvarph.com via the `immich` upstream (127.0.0.1:2283).
  # autoheal and the two metrics exporters from the compose stack are gone:
  # podman's health-on-failure plus systemd restarts replace autoheal.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks volumes;
    version = "v3.2.2";
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the datasets are missing.
      ConditionPathIsMountPoint = ["/flash/immich" "/tank/immich" "/tank/storage"];
    };
  in {
    # Fixed subnet so the gateway (nginx's address inside the network) can be
    # named as a trusted proxy; otherwise Immich logs it instead of the client.
    networks.immich.networkConfig = {
      subnets = ["10.90.1.0/24"];
      gateways = ["10.90.1.1"];
    };
    # ML model downloads; disposable.
    volumes.immich-model-cache = {};

    containers.immich-database = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        # Immich's own Postgres 14 build with VectorChord + pgvecto.rs; keep as is.
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0";
        environmentFiles = [config.age.secrets.immich_db_env.path];
        environments.POSTGRES_INITDB_ARGS = "--data-checksums";
        networks = [networks.immich.ref];
        volumes = ["/flash/immich/postgres:/var/lib/postgresql/data:U"];
        shmSize = "128m";
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "always";
    };

    containers.immich-redis = {
      autoStart = true;
      containerConfig = {
        image = "docker.io/redis:6.2-alpine@sha256:905c4ee67b8e0aa955331960d2aa745781e6bd89afc44a8584bfd13bc890f0ae";
        networks = [networks.immich.ref];
        userns = "auto";
        noNewPrivileges = true;
        healthCmd = "redis-cli ping";
        healthInterval = "30s";
        healthRetries = 3;
      };
      serviceConfig.Restart = "always";
    };

    containers.immich-machine-learning = {
      autoStart = true;
      containerConfig = {
        image = "ghcr.io/immich-app/immich-machine-learning:${version}-openvino";
        environmentFiles = [config.age.secrets.immich_env.path];
        # OpenVINO on the iGPU only needs the render node; the USB passthrough
        # from the compose override was for Movidius sticks.
        devices = ["/dev/dri"];
        networks = [networks.immich.ref];
        volumes = ["${volumes.immich-model-cache.ref}:/cache"];
        noNewPrivileges = true;
        # Replaces autoheal: a failing health check kills the container and systemd restarts it.
        healthCmd = "python3 healthcheck.py";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "120s";
        healthRetries = 3;
        healthOnFailure = "kill";
        notify = "healthy";
      };
      serviceConfig.Restart = "always";
    };

    containers.immich-server = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["immich-database.service" "immich-redis.service"];
          # Wants, not Requires: a slow first pull of a dependency must not cancel
          # this start job for good; Immich retries the DB itself and Restart covers the rest.
          Wants = ["immich-database.service" "immich-redis.service"];
        };
      containerConfig = {
        image = "ghcr.io/immich-app/immich-server:${version}";
        environmentFiles = [config.age.secrets.immich_env.path];
        environments = {
          DB_HOSTNAME = "immich-database";
          REDIS_HOSTNAME = "immich-redis";
          TZ = "Europe/Prague";
          # Prometheus metrics on 8081 (API) and 8082 (jobs), scraped by vmagent.
          IMMICH_TELEMETRY_INCLUDE = "all";
          # Real client IPs in "Failed login attempt" lines (crowdsec reads them).
          IMMICH_TRUSTED_PROXIES = "10.90.1.1";
        };
        # QSV transcoding; runs as root inside like the compose stack did, since
        # thumbs and backups are root-owned and the library is shared with gvarph.
        devices = ["/dev/dri"];
        networks = [networks.immich.ref];
        # Loopback only: the app and web go through nginx.
        # Metrics on 1808x host-side: 8082 is crowdsec's LAPI.
        publishPorts = ["127.0.0.1:2283:2283" "127.0.0.1:18081:8081" "127.0.0.1:18082:8082"];
        volumes = [
          "/tank/immich/library:/usr/src/app/upload"
          "/flash/immich/thumbs:/data/thumbs"
          "/tank/immich/backups:/data/backups"
          "/tank/storage/family_backup/_immich_clean:/data/family_backup:ro"
        ];
        noNewPrivileges = true;
        healthCmd = "immich-healthcheck";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "60s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "always";
    };
  };

  systemd.services = {
    immich-database.restartTriggers = [config.age.secrets.immich_db_env.file];
    immich-server.restartTriggers = [config.age.secrets.immich_env.file];
    immich-machine-learning.restartTriggers = [config.age.secrets.immich_env.file];
  };
}
