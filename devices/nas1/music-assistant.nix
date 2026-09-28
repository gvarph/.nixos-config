{...}: {
  # Music Assistant natively (nixpkgs tracks upstream within days). State is the
  # rpool/flash/music-assistant dataset mounted at the module's DynamicUser path.
  # nginx fronts music-assistant.gvarph.com -> :8095.
  services.music-assistant = {
    enable = true;
    # Everything enabled in settings.json; the module installs each provider's deps.
    providers = [
      "airplay"
      "audiobookshelf"
      "chromecast"
      "dlna"
      "filesystem_local"
      "lastfm_recommendations"
      "local_audio"
      "opensubsonic"
      "party"
      "smart_fades"
      "sonos"
    ];
    # Stream port 8097, AirPlay 7000 + UDP range, Sendspin 8927.
    openFirewall = true;
  };
  # Web/API on 8095: Home Assistant's integration on 10.0.30.117 talks to it directly.
  networking.firewall.allowedTCPPorts = [8095];

  systemd.services.music-assistant = {
    after = ["zfs-mount.service"];
    # Never write state into rpool/root if the dataset is missing.
    unitConfig.ConditionPathIsMountPoint = "/var/lib/private/music-assistant";
  };
}
