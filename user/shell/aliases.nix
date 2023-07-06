{ config, pkgs, ... }:

{
  home.shellAliases = {
    sudo = "sudo ";

    #nix stuff
    gc-check = "nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\w+-system|\{memory|/proc)\"";
    no-rebuild-fast = "sudo nixos-rebuild switch --fast";

    nix-fish = "nix-shell --run fish -p fish ";


    #navigation
    "cd." = "cd ..";
    "cd.." = "cd ../..";
    "cd..." = "cd ../../..";
    "cd...." = "cd ../../../..";
    "cd....." = "cd ../../../../..";
    "cd......" = "cd ../../../../../..";
    "cd......." = "cd ../../../../../../..";
  };
}
