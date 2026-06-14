{
  pkgs,
  username,
  ...
}: {
  home-manager.users.${username} = {
    imports = [
      (import ./wayland {inherit pkgs;})
      (import ./packages {inherit pkgs;})
    ];
  };
}
