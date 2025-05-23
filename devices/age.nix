{
  config,
  pkgs,
  ...
}: {
  age.secrets.nas_auth.file = ../../secrets/nas_auth.age;
  age.identityPaths = [
    "/home/gvarph/.ssh/id_ed25519"
  ];
}
