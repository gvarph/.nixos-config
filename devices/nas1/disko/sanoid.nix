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

  # TODO: everything replicates only within this machine (NVMe -> HDD).
  # tank/* has no second copy at all — add an off-machine syncoid target
  # (serv1 or cloud) at least for the irreplaceable datasets
  # (immich, paperless, storage).
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
