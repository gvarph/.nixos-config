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
    };
  };
}
