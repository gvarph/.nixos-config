{
  config,
  pkgs,
  ...
}: {
  # DisplayLink video driver support
  services.xserver = {
    videoDrivers = ["displaylink" "modesetting"];
  };

  # DisplayLink service configuration
  systemd.services.displaylink-server = {
    enable = true;
    requires = ["systemd-udevd.service"];
    after = ["systemd-udevd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = 5; # Wait 5 seconds before restarting
    };
  };

  # EVDI kernel module for DisplayLink
  boot.initrd.kernelModules = ["evdi"];
  boot.extraModulePackages = [
    config.boot.kernelPackages.evdi
  ];
}
