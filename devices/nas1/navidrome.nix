{...}: {
  # Replaces the deluan/navidrome container. nginx keeps proxying
  # navidrome.gvarph.com to localhost:4533 with oauth2-proxy in front.
  services.navidrome = {
    enable = true;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      DataFolder = "/flash/navidrome";
      CacheFolder = "/flash/navidrome/cache";
      MusicFolder = "/tank/media/music";
      Scanner.Schedule = "1h";
      LogLevel = "info";
      SessionTimeout = "24h";
      Prometheus.Enabled = true;
      # oauth2-proxy sets X-Forwarded-User; trust it from nginx on loopback only.
      # /rest/ and /share/ stay outside SSO (see nginx.nix).
      ExtAuth = {
        UserHeader = "X-Forwarded-User";
        TrustedSources = "127.0.0.1/32,::1/128";
        LogoutURL = "https://auth.gvarph.com/oauth2/sign_out?rd=https://navidrome.gvarph.com";
      };
    };
  };

  # Never write state into rpool/root if the dataset is missing.
  systemd.services.navidrome = {
    after = ["zfs-mount.service"];
    unitConfig.ConditionPathIsMountPoint = "/flash/navidrome";
  };
}
