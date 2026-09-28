{config, ...}: {
  # Shelfarr: audiobook/ebook automation on the servarr network (its Prowlarr,
  # SABnzbd and qBittorrent clients are stored by IP). Reaches Audiobookshelf
  # over that app's network: set its ABS URL to http://audiobookshelf:13378.
  # nginx fronts shelfarr.gvarph.com -> :5056 (native OIDC).
  virtualisation.quadlet.containers.shelfarr = let
    inherit (config.virtualisation.quadlet) networks;
  in {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the datasets are missing.
      ConditionPathIsMountPoint = ["/flash/shelfarr" "/tank/media"];
    };
    containerConfig = {
      image = "ghcr.io/pedro-revez-silva/shelfarr:2026.08.24.1";
      # Starts as root, chowns, drops to PUID; imports hardlinks into the
      # shared media tree as gvarph:users, so no private user namespace.
      environments = {
        SOLID_QUEUE_IN_PUMA = "1";
        PUID = "1000";
        PGID = "100";
        CHOWN_ON_START = "auto";
      };
      # With two networks the static address must be given per network.
      networks = ["${networks.servarr.ref}:ip=172.39.0.15" networks.audiobookshelf.ref];
      publishPorts = ["127.0.0.1:5056:80"];
      # Binds :80 after dropping to PUID; docker allowed that via this sysctl by default.
      sysctl."net.ipv4.ip_unprivileged_port_start" = "0";
      volumes = [
        "/flash/shelfarr/data:/rails/storage"
        "/tank/media/audiobooks:/audiobooks"
        "/tank/media/ebooks:/ebooks"
        "/tank/media/completed:/downloads"
        "/tank/media:/data"
      ];
      noNewPrivileges = true;
      healthCmd = "curl -f http://localhost:80/up";
      healthInterval = "30s";
      healthTimeout = "10s";
      healthStartPeriod = "40s";
      healthRetries = 3;
      notify = "healthy";
    };
    serviceConfig.Restart = "on-failure";
  };
}
