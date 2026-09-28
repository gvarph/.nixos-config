{config, ...}: {
  age.secrets.hevy2garmin_env.file = ../../secrets/hevy2garmin_env.age;

  # Syncs Hevy workouts to Garmin Connect. No published image, so it is built
  # from the pinned upstream commit (v0.10.1-125-g164db8b) that ~/hevy2garmin held.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) builds;
    src = builtins.fetchGit {
      url = "https://github.com/drkostas/hevy2garmin.git";
      rev = "164db8be4850ed43ef59c0fec8e063f4a9689202";
    };
  in {
    builds.hevy2garmin.buildConfig = {
      tag = "localhost/hevy2garmin:164db8b";
      workdir = "${src}";
    };

    containers.hevy2garmin = {
      autoStart = true;
      unitConfig = {
        After = ["zfs-mount.service"];
        # Never write state into rpool/root if the dataset is missing.
        ConditionPathIsMountPoint = "/flash/hevy2garmin";
      };
      containerConfig = {
        image = builds.hevy2garmin.ref;
        exec = "serve";
        environmentFiles = [config.age.secrets.hevy2garmin_env.path];
        # Loopback only: oauth2-proxy -> Pocket ID fronts it at hevy.gvarph.com.
        publishPorts = ["127.0.0.1:8124:8123"];
        # Garmin tokens (~yearly, connected via the dashboard) and sync state.
        volumes = [
          "/flash/hevy2garmin/app:/root/.hevy2garmin:U"
          "/flash/hevy2garmin/garmin:/root/.garminconnect:U"
        ];
        userns = "auto";
        dropCapabilities = ["ALL"];
        noNewPrivileges = true;
        # Same probe as the image's HEALTHCHECK; podman's sdnotify=healthy needs it explicit.
        healthCmd = ''python -c 'import urllib.request,sys; sys.exit(0 if urllib.request.urlopen("http://127.0.0.1:8123/login", timeout=4).status < 500 else 1)' '';
        healthInterval = "60s";
        healthTimeout = "5s";
        healthStartPeriod = "20s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };
  };

  systemd.services.hevy2garmin.restartTriggers = [config.age.secrets.hevy2garmin_env.file];
}
