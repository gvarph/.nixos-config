{config, ...}: {
  age.secrets."9router_env".file = ../../secrets/9router_env.age;

  # 9router: AI routing proxy behind nginx (dashboard via oauth2-proxy, API
  # paths gated by its own keys).
  # Provider OAuth flows redirect to localhost:20128; use the paste-the-code option.
  # Network so paperless-gpt reaches it as http://9router:20128.
  virtualisation.quadlet.networks."9router" = {};
  virtualisation.quadlet.containers."9router" = {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service"];
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
      };
      networks = [config.virtualisation.quadlet.networks."9router".ref];
      publishPorts =["127.0.0.1:20128:20128"];
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

  systemd.services."9router".restartTriggers = [config.age.secrets."9router_env".file];
}
