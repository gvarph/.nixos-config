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
    lt3 = "exa --tree --level=3" + exa_args;
    lt4 = "exa --tree --level=4" + exa_args;
    lt5 = "exa --tree --level=5" + exa_args;

    lta = "exa --tree --level=2 -a" + exa_args;
    lt3a = "exa --tree --level=3 -a" + exa_args;
    lt4a = "exa --tree --level=4 -a" + exa_args;
    lt5a = "exa --tree --level=5 -a" + exa_args;
  };
}
