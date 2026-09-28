{config, ...}: {
  age.secrets.jellystat_env.file = ../../secrets/jellystat_env.age;

  # Jellyfin with Intel QSV transcoding, plus Jellystat and its Postgres.
  # Jellyseerr stays in the compose stack until the arr network moves (it is
  # pinned on servarrnetwork). nginx fronts jellyfin/jf and jellystat.gvarph.com.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks;
    guard = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the datasets are missing.
      ConditionPathIsMountPoint = ["/flash/jellyfin" "/tank/media"];
    };
  in {
    networks.jellyfin = {};

    containers.jellyfin = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/jellyfin/jellyfin:10.11.11";
        # Shares the media tree as gvarph:users, so no private user namespace.
        user = "1000:100";
        # render (303) and video (26) for /dev/dri; QSV uses renderD128.
        addGroups = ["303" "26"];
        devices = ["/dev/dri"];
        networks = [networks.jellyfin.ref];
        # Loopback only: clients go through nginx. Discovery (7359/udp) dropped with it.
        publishPorts = ["127.0.0.1:8096:8096"];
        addHosts = ["host.docker.internal:host-gateway"];
        volumes = [
          "/flash/jellyfin/config:/config"
          "/flash/jellyfin/cache:/cache"
          "/tank/media/movies:/media/movies:ro"
          "/tank/media/tv:/media/tv:ro"
        ];
        noNewPrivileges = true;
        healthCmd = "curl -fsS http://localhost:8096/health";
        healthInterval = "30s";
        healthTimeout = "10s";
        healthStartPeriod = "60s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.jellystat-db = {
      autoStart = true;
      unitConfig = guard;
      containerConfig = {
        image = "docker.io/library/postgres:17.11";
        environmentFiles = [config.age.secrets.jellystat_env.path];
        networks = [networks.jellyfin.ref];
        volumes = ["/flash/jellyfin/jellystat/postgres:/var/lib/postgresql/data:U"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers.jellystat = {
      autoStart = true;
      unitConfig =
        guard
        // {
          After = guard.After ++ ["jellystat-db.service" "jellyfin.service"];
          Requires = ["jellystat-db.service"];
        };
      containerConfig = {
        image = "docker.io/cyfershepard/jellystat:1.1.12";
        environmentFiles = [config.age.secrets.jellystat_env.path];
        environments = {
          POSTGRES_IP = "jellystat-db";
          POSTGRES_PORT = "5432";
          TZ = "America/Los_Angeles";
        };
        networks = [networks.jellyfin.ref];
        publishPorts = ["127.0.0.1:13000:3000"];
        volumes = ["/flash/jellyfin/jellystat/backup-data:/app/backend/backup-data:U"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services = {
    jellystat-db.restartTriggers = [config.age.secrets.jellystat_env.file];
    jellystat.restartTriggers = [config.age.secrets.jellystat_env.file];
  };
}
