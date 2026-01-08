{
  config,
  pkgs,
  ...
}: let
  # Fetch the repositories
  anyrun = import (fetchTarball "https://github.com/Kirottu/anyrun/archive/master.tar.gz") {};
in {
  programs.anyrun = {
    enable = true;
    config = {
      plugins = with anyrun.packages.${pkgs.stdenv.hostPlatform.system}; [
        applications
        randr
        rink
        shell
        symbols
        translate
      ];

      width.fraction = 0.3;
      y.absolute = 15;
      hidePluginInfo = true;
      closeOnClick = true;
    };

    # custom css for anyrun, based on catppuccin-mocha
    extraCss = builtins.readFile ./style.css;
  };

  # ... any other home-manager configurations ...
}
