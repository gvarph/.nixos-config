{
  config,
  pkgs,
  ...
}: let
  eza_args = " --icons --color=auto --git --binary --header --created --modified --accessed";
in {
  home.packages = with pkgs; [
    eza
  ];

  home.shellAliases = {
    ls = "eza" + eza_args;
    ll = "eza -l" + eza_args;
    la = "eza -a" + eza_args;
    lla = "eza -l -a" + eza_args;
    lt = "eza --tree --level=2" + eza_args;
    lta = "eza --tree --level=2 -a" + eza_args;
  };
}
