{pkgs, ...}: let
  snapshotPolicy = {
    autosnap = true;
    autoprune = true;
    hourly = 36;
    daily = 30;
    monthly = 12;
  };

  datasets = [
    # NVMe app data
    "rpool/flash"
    "rpool/flash/arr"
    "rpool/flash/garage-s3"
    "rpool/flash/immich"
    "rpool/flash/jellyfin"
    "rpool/flash/monitoring"
    "rpool/flash/music-assistant"
    "rpool/flash/nextcloud"
    "rpool/flash/obsidian"
    "rpool/flash/paperless"
    "rpool/flash/pocket-id"
    "rpool/flash/dawarich"

    # HDD datasets
    "tank/immich"
    "tank/storage"
    "tank/paperless"
  ];
in {
  services.sanoid = {
    enable = true;

    datasets = builtins.listToAttrs (map (name: {
        inherit name;
        value = snapshotPolicy;
      })
      datasets);
  };

  services.syncoid = {
    enable = true;

    commands = {
      "backup-flash" = {
        source = "rpool/flash";
        target = "tank/snapshots/flash";
        recursive = true;
        sendOptions = "Pb";
        recvOptions = "u";
      };
    };
  };
}
