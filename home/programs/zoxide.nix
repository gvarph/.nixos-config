{
  config,
  pkgs,
  ...
}: {
  programs.zoxide = {
    enable = true;
  };
  home.shellAliases = {
    "cd" = "z";
  };
}
