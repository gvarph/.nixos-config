{
  config,
  pkgs,
  ...
}: let
  exa_args = " --icons --color=auto --git --binary --header --created --modified --accessed";
in {
  home.packages = with pkgs; [
    exa
  ];

  home.shellAliases = {
    ls = "exa" + exa_args;
    ll = "exa -l" + exa_args;
    la = "exa -a" + exa_args;
    lla = "exa -l -a" + exa_args;
    lt = "exa --tree --level=2" + exa_args;
    lta = "exa --tree --level=2 -a" + exa_args;
  };
}
