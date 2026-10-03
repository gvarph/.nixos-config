{config, ...}: {
  # postgres_exporter / redis_exporter sidecars on each app's private network,
  # scraped by vmagent on loopback (see metrics.nix). The exporters connect to
  # the maintenance database, so pg_stat_database covers every database on
  # the instance and the app's own credentials are enough.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks;
    pgImage = "quay.io/prometheuscommunity/postgres-exporter:v0.20.1";
    redisImage = "docker.io/oliver006/redis_exporter:v1.93.0";
    pgExporter = {
      db,
      network,
      port,
      environments ? {},
      environmentFiles ? [],
      # Env files carry POSTGRES_*; map them to what the exporter reads.
      fromPostgresEnv ? false,
    }: {
      autoStart = true;
      unitConfig = {
        After = ["${db}.service"];
        Wants = ["${db}.service"];
      };
      containerConfig =
        {
          image = pgImage;
          inherit environmentFiles;
          environments =
            environments
            // {DATA_SOURCE_URI = "${db}:5432/postgres?sslmode=disable";};
          networks = [network.ref];
          publishPorts = ["127.0.0.1:${toString port}:9187"];
          userns = "auto";
          noNewPrivileges = true;
        }
        // (
          if fromPostgresEnv
          then {
            entrypoint = "/bin/sh";
            exec = ''-c 'export DATA_SOURCE_USER="$POSTGRES_USER" DATA_SOURCE_PASS="$POSTGRES_PASSWORD"; exec /bin/postgres_exporter' '';
          }
          else {}
        );
      serviceConfig.Restart = "on-failure";
    };
    redisExporter = {
      redis,
      network,
      port,
    }: {
      autoStart = true;
      unitConfig = {
        After = ["${redis}.service"];
        Wants = ["${redis}.service"];
      };
      containerConfig = {
        image = redisImage;
        environments.REDIS_ADDR = "redis://${redis}:6379";
        networks = [network.ref];
        publishPorts = ["127.0.0.1:${toString port}:9121"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  in {
    containers.immich-postgres-exporter = pgExporter {
      db = "immich-database";
      network = networks.immich;
      port = 9187;
      environmentFiles = [config.age.secrets.immich_db_env.path];
      fromPostgresEnv = true;
    };
    containers.paperless-postgres-exporter = pgExporter {
      db = "paperless-db";
      network = networks.paperless;
      port = 9188;
      environments = {
        DATA_SOURCE_USER = "paperless";
        DATA_SOURCE_PASS = "paperless";
      };
    };
    containers.sparkyfitness-postgres-exporter = pgExporter {
      db = "sparkyfitness-db";
      network = networks.sparkyfitness;
      port = 9189;
      environmentFiles = [config.age.secrets.sparkyfitness_db_env.path];
      fromPostgresEnv = true;
    };
    containers.jellystat-postgres-exporter = pgExporter {
      db = "jellystat-db";
      network = networks.jellyfin;
      port = 9190;
      environmentFiles = [config.age.secrets.jellystat_env.path];
      fromPostgresEnv = true;
    };
    containers.immich-redis-exporter = redisExporter {
      redis = "immich-redis";
      network = networks.immich;
      port = 9121;
    };
    containers.paperless-redis-exporter = redisExporter {
      redis = "paperless-broker";
      network = networks.paperless;
      port = 9122;
    };
  };
}
