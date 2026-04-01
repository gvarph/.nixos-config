{
  config,
  pkgs,
  ...
}: {
  age.secrets.nas_auth.file = ./nas_auth.age;
  age.secrets.homelab_k3s_token.file = ./homelab_k3s_token.age;
  age.secrets.cloudflare_dns_api_token.file = ./cloudflare_dns_api_token.age;

  age.identityPaths = [
    "/home/gvarph/.ssh/id_ed25519"
  ];
}
