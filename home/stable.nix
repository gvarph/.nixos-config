{
  pkgs-stable,
  ...
}: {
  
  home.packages = with pkgs-stable; [
    azure-cli
  ];
}
