{ config, pkgs, ... }:
let

in

{
  home.packages = with pkgs; [
    bat

    bat-extras.batman

    ripgrep
    bat-extras.batgrep

  ];


  home.shellAliases = {
    bata = "bat -A";
    batp = "bat --paging=always";
    bat = "bat --paging=never";

    man = "batman";

    batg = "batgrep";
  };
}
