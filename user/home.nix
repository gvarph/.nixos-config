{ config, pkgs, ... }:

{
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix
    ./shell/starship-symbols.nix

    ./shell/exa.nix

    ./shell/aliases.nix
  ];

  home.packages = with pkgs; [
    bat
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
