{
  config,
  pkgs,
  ...
}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      # Readable by wheel (for kubectl as the regular user) but not world-readable
      "--write-kubeconfig-mode=640"
      "--write-kubeconfig-group=wheel"
      "--cluster-init"
    ];
  };

  networking.firewall.allowedTCPPorts = [6443];

  # Make the local k3s cluster the default for kubectl/k9s.
  # Switch to the work (gcloud-managed) cluster per-shell with `kwork`.
  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
}
