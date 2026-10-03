{config, ...}: {
  age.secrets."9router_env".file = ../../secrets/9router_env.age;

  # 9router: AI routing proxy behind nginx (dashboard via oauth2-proxy, API
  # paths gated by its own keys). headroom is its token-saver sidecar.
  # Provider OAuth flows redirect to localhost:20128; use the paste-the-code option.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks volumes;
  in {
    # Private network so 9router reaches the sidecar as http://headroom:8787.
    networks."9router" = {};
    # Sidecar cache/config only; not worth a dataset.
    volumes.headroom-state = {};

    containers.headroom = {
      autoStart = true;
      containerConfig = {
        # v0.39.1 build d13e196 (what :latest was on 2026-09-28); no plain tag has it.
        image = "ghcr.io/headroomlabs-ai/headroom@sha256:90c21af0f32a314b1758ac3904be802ab32af517c701c3542ee9671925109f5e";
        networks = [networks."9router".ref];
        volumes = ["${volumes.headroom-state.ref}:/home/nonroot/.headroom"];
        userns = "auto";
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    containers."9router" = {
      autoStart = true;
      unitConfig = {
        After = ["zfs-mount.service" "headroom.service"];
        Requires = ["headroom.service"];
        # Never write state into rpool/root if the dataset is missing.
        ConditionPathIsMountPoint = "/flash/9router";
      };
      containerConfig = {
        image = "docker.io/decolua/9router:0.5.95";
        environmentFiles = [config.age.secrets."9router_env".path];
        environments = {
          DATA_DIR = "/app/data";
          PORT = "20128";
          HOSTNAME = "0.0.0.0";
          NODE_ENV = "production";
          HEADROOM_URL = "http://headroom:8787";
        };
        networks = [networks."9router".ref];
        publishPorts = ["127.0.0.1:20128:20128"];
        # SQLite (providers, OAuth tokens, keys, usage) at db/data.sqlite.
        volumes = ["/flash/9router:/app/data:U"];
        userns = "auto";
        # Entrypoint runs as root only to chown the data mount, then drops to `node`.
        dropCapabilities = ["ALL"];
        addCapabilities = ["CHOWN" "SETUID" "SETGID"];
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services."9router".restartTriggers = [config.age.secrets."9router_env".file];
}
