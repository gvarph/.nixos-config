{ config, pkgs, ... }:

{
  imports = [
    ./shell/fish.nix
    ./shell/starship.nix
  ];

  home.packages = with pkgs; [
    bat
    exa
    fd
    ripgrep
    tokei
    tealdeer
    fzf
    procs
    prettyping
    gzip
    unzip
    htop
    bottom
    neofetch
    tree

  ];

  home.stateVersion = "23.05";

}
