{config, ...}: {
  # Jellyseerr: requests for Jellyfin, submitted to Radarr/Sonarr on the servarr
  # network (stored there by IP). nginx fronts js.gvarph.com -> :5055.
  virtualisation.quadlet.containers.jellyseerr = let
    inherit (config.virtualisation.quadlet) networks;
  in {
    autoStart = true;
    unitConfig = {
      After = ["zfs-mount.service"];
      # Never write state into rpool/root if the dataset is missing.
      ConditionPathIsMountPoint = "/flash/jellyfin";
    };
    containerConfig = {
      # The project moved to ghcr.io/seerr-team/seerr (v3); upgrade separately.
      image = "docker.io/fallenbagel/jellyseerr:2.7.3";
      environments = {
        PUID = "1000";
        PGID = "100";
        TZ = "America/Los_Angeles";
      };
      # Also on the jellyfin network so its stored hostname `jellyfin` resolves.
      # With two networks the static address must be given per network.
      networks = ["${networks.servarr.ref}:ip=172.39.0.10" networks.jellyfin.ref];
      publishPorts = ["127.0.0.1:5055:5055"];
      volumes = ["/flash/jellyfin/jellyseerr/config:/app/config:U"];
      # Talks to APIs only; its entrypoint chowns to PUID, hence the wide map.
      userns = "auto:size=65536";
      noNewPrivileges = true;
    };
    serviceConfig.Restart = "on-failure";
  };
}
