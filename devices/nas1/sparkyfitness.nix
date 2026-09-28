{config, ...}: {
  age.secrets.sparkyfitness_env.file = ../../secrets/sparkyfitness_env.age;
  age.secrets.sparkyfitness_db_env.file = ../../secrets/sparkyfitness_db_env.age;

  # SparkyFitness (server + frontend + Postgres). The frontend image runs its own
  # nginx that proxies /api to the server; host nginx fronts fitness.gvarph.com.
  # The compose stack's postgres exporter was dropped with the metrics stack.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks;
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/sparkyfitness";
    };
  in {
    networks.sparkyfitness = {};

    containers.sparkyfitness-db = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/library/postgres:18.3-alpine";
        environmentFiles = [config.age.secrets.sparkyfitness_db_env.path];
        networks = [networks.sparkyfitness.ref];
        volumes = ["/flash/sparkyfitness/postgresql:/var/lib/postgresql:U"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.sparkyfitness-server = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["sparkyfitness-db.service"];
          Requires = ["sparkyfitness-db.service"];
        };
      containerConfig = {
        image = "docker.io/codewithcj/sparkyfitness_server:v1.7.3";
        environmentFiles = [config.age.secrets.sparkyfitness_env.path];
        # Container-to-container only: never a host port.
        environments = {
          SPARKY_FITNESS_DB_HOST = "sparkyfitness-db";
          SPARKY_FITNESS_DB_PORT = "5432";
        };
        networks = [networks.sparkyfitness.ref];
        volumes = [
          "/flash/sparkyfitness/backup:/app/SparkyFitnessServer/backup:U"
          "/flash/sparkyfitness/uploads:/app/SparkyFitnessServer/uploads:U"
        ];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.sparkyfitness-frontend = {
      autoStart = true;
      unitConfig = {
        After = ["sparkyfitness-server.service"];
        Requires = ["sparkyfitness-server.service"];
      };
      containerConfig = {
        image = "docker.io/codewithcj/sparkyfitness:v1.7.3";
        environments = {
          SPARKY_FITNESS_FRONTEND_URL = "https://fitness.gvarph.com";
          SPARKY_FITNESS_SERVER_HOST = "sparkyfitness-server";
          SPARKY_FITNESS_SERVER_PORT = "3010";
        };
        networks = [networks.sparkyfitness.ref];
        publishPorts = ["127.0.0.1:3004:80"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services = {
    sparkyfitness-db.restartTriggers = [config.age.secrets.sparkyfitness_db_env.file];
    sparkyfitness-server.restartTriggers = [config.age.secrets.sparkyfitness_env.file];
  };
}
