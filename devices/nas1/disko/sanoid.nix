{pkgs, ...}: {
  services.sanoid = {
    enable = true;
    datasets = {
      "rpool/flash" = {
        autosnap = true;
        autoprune = true;
        hourly = 36;
        daily = 30;
        monthly = 12;
      };
      "rpool/immich" = {
        autosnap = true;
        autoprune = true;
        hourly = 36;
        daily = 30;
        monthly = 12;
      };
      "rpool/storage" = {
        autosnap = true;
        autoprune = true;
        hourly = 36;
        daily = 30;
        monthly = 12;
      };
      "rpool/paperless" = {
        autosnap = true;
        autoprune = true;
        hourly = 36;
        daily = 30;
        monthly = 12;
      };
    };
  };

  # --- SYNCOID CONFIG ---
  services.syncoid = {
    enable = true;
    commands = {
      "backup-flash" = {
        source = "rpool/flash";
        target = "tank/snapshots/flash";
        recursive = true;
        sendOptions = "P";
        recvOptions = "u";
      };
      "backup-immich" = {
        source = "rpool/immich";
        target = "tank/snapshots/immich";
        recursive = true;
        sendOptions = "P";
        recvOptions = "u";
      };
      "backup-storage" = {
        source = "rpool/storage";
        target = "tank/snapshots/storage";
        recursive = true;
        sendOptions = "P";
        recvOptions = "u";
      };
      "backup-paperless" = {
        source = "rpool/paperless";
        target = "tank/snapshots/paperless";
        recursive = true;
        sendOptions = "P";
        recvOptions = "u";
      };
    };
  };
}
