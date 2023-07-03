{ ... }:

let
  exa_args = " --icons --color=auto";
in

{
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
}
