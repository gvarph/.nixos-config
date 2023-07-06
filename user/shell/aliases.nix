{ config, pkgs, ... }:

{
  home.shellAliases = {
    sudo = "sudo ";

    #nix stuff
    gc-check = "nix-store --gc --print-roots | egrep -v \"^(/nix/var|/run/\w+-system|\{memory|/proc)\"";
    no-rebuild-fast = "sudo nixos-rebuild switch --fast";

    nix-fish = "nix-shell --run fish -p fish ";

    please = "sudo $(history - p !!)";

    cp = "cp -iv"; #confirm before overwriting
    mv = "mv -iv"; #confirm before overwriting

    mkdir = "mkdir -pv"; #create parent directories if needed

    #create a directory and cd into it
    cmkdir = "mkdir -p \"$1\" && cd \"$1\"";
    mcd = "cmkdir";

    # go up by number of dots
    "cd.." = "cd .."; # go up one directory
    "cd..." = "cd ../.."; # go up two directories
    "cd...." = "cd ../../.."; # go up three directories
    "cd....." = "cd ../../../.."; # go up four directories
    "cd......" = "cd ../../../../.."; # go up five directories
    "cd......." = "cd ../../../../../.."; # go up six directories

    # go up by a number 
    "cd.2" = "cd ../.."; # go up two directories
    "cd.3" = "cd ../../.."; # go up three directories
    "cd.4" = "cd ../../../.."; # go up four directories
    "cd.5" = "cd ../../../../.."; # go up five directories
    "cd.6" = "cd ../../../../../.."; # go up six directories
    "cd.7" = "cd ../../../../../../.."; # go up seven directories
  };
}
