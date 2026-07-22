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
    "rpool/flash/trek"

    # HDD datasets
    "tank/immich"
    "tank/storage"
    "tank/paperless"
    "tank/media"
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

  # Off-machine copies of the irreplaceable datasets go to a Hetzner
  # Storage Box via restic (see ../restic.nix). TODO: buddy-NAS
  # replication with a friend's NAS as a second off-site leg.
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
