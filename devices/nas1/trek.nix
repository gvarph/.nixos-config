{config, ...}: {
  age.secrets.trek_env.file = ../../secrets/trek_env.age;

  # Same hardening as the old compose stack; nginx proxies trek.gvarph.com to :3100.
  virtualisation.quadlet.containers.trek = {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/trek";
    };
    containerConfig = {
      image = "docker.io/mauriceboe/trek:4.3.3";
      environmentFiles = [config.age.secrets.trek_env.path];
      # Loopback only: nginx is the front door, and 3100 sits in the LAN-open range.
      publishPorts = ["127.0.0.1:3100:3000"];
      # :U re-owns the data to the container's mapped uid on each start.
      volumes = [
        "/flash/trek/data:/app/data:U"
        "/flash/trek/uploads:/app/uploads:U"
      ];
      userns = "auto";
      readOnly = true;
      tmpfses = ["/tmp:noexec,nosuid,size=128m"];
      dropCapabilities = ["ALL"];
      addCapabilities = ["CHOWN" "SETUID" "SETGID"];
      noNewPrivileges = true;
      healthCmd = "wget -qO- http://localhost:3000/api/health";
      healthInterval = "30s";
      healthStartPeriod = "15s";
      healthRetries = 3;
      healthTimeout = "10s";
      # The unit counts as started only once the health check passes.
      notify = "healthy";
    };
    serviceConfig.Restart = "on-failure";
  };
  # podman reads the env file only at container creation; restart on rotation.
  systemd.services.trek.restartTriggers = [config.age.secrets.trek_env.file];
}
