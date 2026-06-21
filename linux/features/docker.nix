{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
    # autoPrune runs `docker system prune`, which also removes containers and
    # networks. We only want images cleaned, so we disable it and use the
    # dedicated timer below instead.
    autoPrune.enable = false;
    extraOptions = ''
      --default-ulimit nofile=65535:65535
      --default-ulimit nproc=65535:65535
    '';
  };

  systemd.services.docker-prune-images = {
    description = "Prune unused Docker images";
    requires = ["docker.service"];
    after = ["docker.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.docker}/bin/docker image prune -af";
    };
  };

  systemd.timers.docker-prune-images = {
    description = "Periodically prune unused Docker images";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
