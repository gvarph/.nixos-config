{...}: {
  # Replaces the binwiederhier/ntfy container. nginx keeps proxying
  # ntfy.gvarph.com to localhost:8091, so only the listener moved.
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.gvarph.com";
      listen-http = "127.0.0.1:8091";
      behind-proxy = true;
      auth-default-access = "deny-all";
      cache-duration = "24h";
      enable-metrics = true;
      # crowdsec's ntfy parser extracts visitor_ip from JSON log lines.
      log-format = "json";
    };
  };

  # The module runs as a DynamicUser with StateDirectory, so its state must sit
  # at the private path systemd re-chowns on every start. The rpool/flash/ntfy
  # dataset is mounted right there (mountpoint set by hand; the parent is legacy).
  systemd.services.ntfy-sh = {
    after = ["zfs-mount.service"];
    # Skip rather than write a fresh state into rpool/root if the dataset is missing.
    unitConfig.ConditionPathIsMountPoint = "/var/lib/private/ntfy-sh";
  };
  # zfs-mount creates the parent 0755; systemd insists on 0700 here.
  systemd.tmpfiles.rules = ["d /var/lib/private 0700 root root -"];
}
