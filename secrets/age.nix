{
  config,
  pkgs,
  ...
}: {
  age.secrets.homelab_k3s_token.file = ./homelab_k3s_token.age;

  age.identityPaths = [
    "/home/gvarph/.ssh/id_ed25519"
  ];
}
