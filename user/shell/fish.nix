{ config, pkgs, ... }:

let
  exa_args = " --icons --color=auto";

in

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
      ls = "exa" + exa_args;
      ll = "exa -l" + exa_args;
      la = "exa -a" + exa_args;
      lla = "exa -l -a" + exa_args;


      no-rebuild-fast = "sudo nixos-rebuild switch --fast";


      "cd." = "cd ..";
      "cd.." = "cd ../..";
      "cd..." = "cd ../../..";
      "cd...." = "cd ../../../..";
      "cd....." = "cd ../../../../..";

    };
  };
}
