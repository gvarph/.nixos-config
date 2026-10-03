{config, ...}: {
  # Audiobookshelf on the upstream image (the nixpkgs module lags releases), plus
  # the WatchShelf sidecar that transcodes for the Garmin watch app. nginx fronts
  # ab.gvarph.com (direct, not Cloudflare) and watchshelf.gvarph.com.
  virtualisation.quadlet = let
    inherit (config.virtualisation.quadlet) networks volumes builds;
    watchshelf = builtins.fetchGit {
      url = "https://github.com/JediBrooker/WatchShelf.git";
      rev = "714fd3af002e9af3ec600bb884d909aa09409634";
    };
  in {
    # Private network so the sidecar reaches ABS as http://audiobookshelf:13378.
    networks.audiobookshelf = {};
    # Watch refresh tokens; a redeploy must not force a re-login on the watch.
    volumes.watchshelf-data = {};

    containers.audiobookshelf = {
      autoStart = true;
      unitConfig = {
        After = ["zfs-mount.service"];
        # Never write state into rpool/root if the dataset is missing.
        ConditionPathIsMountPoint = "/flash/audiobookshelf";
      };
      containerConfig = {
        image = "ghcr.io/advplyr/audiobookshelf:2.37.1";
        # Shares the media tree with other containers as gvarph:users, so it
        # runs as that uid instead of in a private user namespace.
        user = "1000:100";
        # Non-root cannot bind :80 in the container.
        environments.PORT = "13378";
        networks = [networks.audiobookshelf.ref];
        publishPorts = ["127.0.0.1:13378:13378"];
        volumes = [
          "/flash/audiobookshelf/config:/config"
          "/flash/audiobookshelf/metadata:/metadata"
          "/tank/media/audiobooks:/audiobooks"
          "/tank/media/audiobooks-royal_guard_beta_reading:/audiobooks-royal_guard_beta_reading"
          "/tank/media/podcasts:/podcasts"
          # Ebooks delivered by Shelfarr (its /data/ebooks).
          "/tank/media/ebooks:/ebooks"
        ];
        noNewPrivileges = true;
      };
      serviceConfig.Restart = "on-failure";
    };

    builds.watchshelf-sidecar.buildConfig = {
      tag = "localhost/watchshelf-sidecar:714fd3af";
      workdir = "${watchshelf}/sidecar";
    };

    containers.watchshelf-sidecar = {
      autoStart = true;
      unitConfig = {
        After = ["audiobookshelf.service"];
        Requires = ["audiobookshelf.service"];
      };
      containerConfig = {
        image = builds.watchshelf-sidecar.ref;
        environments = {
          ABS_URL = "http://audiobookshelf:13378";
          BIND = "0.0.0.0";
          PORT = "8081";
          SESSIONS_FILE = "/data/sessions.json";
        };
        networks = [networks.audiobookshelf.ref];
        publishPorts = ["127.0.0.1:8081:8081"];
        volumes = ["${volumes.watchshelf-data.ref}:/data"];
        userns = "auto";
        noNewPrivileges = true;
        healthCmd = "wget -qO- http://127.0.0.1:8081/health";
        healthInterval = "1m";
        healthTimeout = "5s";
        healthStartPeriod = "10s";
        healthRetries = 3;
        notify = "healthy";
      };
      serviceConfig.Restart = "on-failure";
    };
  };
}
