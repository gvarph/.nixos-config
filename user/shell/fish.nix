{ config, pkgs, ... }:



{

  home.packages = with pkgs; [
    fishPlugins.fzf-fish
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.done
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';


    plugins = [

      # fishPlugins.grc
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }

      # fishPlugins.fzf-fish
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }

      # fishPlugins.forgit
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }

      # fishPlugins.hydro
      { name = "hydro"; src = pkgs.fishPlugins.hydro.src; }

      # fishPlugins.done
      { name = "done"; src = pkgs.fishPlugins.done.src; }
    ];

    interactiveShellInit = ''
      set -g theme_nerd_fonts yes

      direnv hook fish | source
    '';

    shellAliases = import ./aliases.nix;
  };
}
