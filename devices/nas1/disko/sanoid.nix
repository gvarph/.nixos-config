{pkgs, ...}: let
  # List only the datasets you want to snapshot and backup
  monitoredDatasets = [
    "flash"
    "garage-s3"
    "immich"
    "music-assistant"
    "nextcloud"
    "obsidian"
    "paperless"
  ];
in {
  services.sanoid = {
    enable = true;
    # We use 'builtins.listToAttrs' to turn our list into the format Sanoid expects
    datasets = builtins.listToAttrs (map (name: {
        name = "rpool/${name}";
        value = {
          autosnap = true;
          autoprune = true;
          hourly = 36;
          daily = 30;
          monthly = 12;
        };
      })
      monitoredDatasets);
  };

  # --- SYNCOID CONFIG ---
  services.syncoid = {
    enable = true;
    commands = builtins.listToAttrs (map (name: {
        name = "backup-${name}";
        value = {
          source = "rpool/${name}";
          target = "tank/snapshots/${name}";
          recursive = false;
          sendOptions = "P";
          recvOptions = "u";
        };
      })
      monitoredDatasets);
  };
}
