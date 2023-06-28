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
      set fish_greeting # no greeting
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

    shellAliases = {
      ls = "exa --color=auto";
      ll = "exa --color=auto -l";
      la = "exa --color=auto -a";
      lla = "exa --color=auto -la";

      no-rebuild-fast = " sudo nixos-rebuild switch --fast -I nixos-config=\"/home/gvarph/.nixos-config/configuration.nix\"";

      no-rebuild-fast-default = "sudo nixos-rebuild switch --fast";


      "cd." = "cd ..";
      "cd.." = "cd ../..";
      "cd..." = "cd ../../..";
      "cd...." = "cd ../../../..";
      "cd....." = "cd ../../../../..";

    };
  };
}
