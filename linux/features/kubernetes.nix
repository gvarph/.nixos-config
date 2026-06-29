{
  config,
  pkgs,
  ...
}: {
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
      "--cluster-init"
    ];
  };

  networking.firewall.allowedTCPPorts = [6443];

  # Make the local k3s cluster the default for kubectl/k9s.
  # Switch to the work (gcloud-managed) cluster per-shell with `kwork`.
  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
}
