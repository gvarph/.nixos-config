{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    extraOptions = ''
      --default-ulimit nofile=65535:65535
      --default-ulimit nproc=65535:65535
    '';
  };
}
