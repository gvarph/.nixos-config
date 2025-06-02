{
  config,
  pkgs,
  ...
}: {
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = config.age.secrets.homelab_k3s_token.path;
    extraFlags = toString [
      "--write-kubeconfig-mode=644"
      "--cluster-init"
      "--disable"
      "traefik"
    ];
  };

  networking.firewall.allowedTCPPorts = [6443];
}
