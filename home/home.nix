{ config, pkgs, ... }:

{
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix
    ./shell/starship-symbols.nix

    ./shell/exa.nix
    ./shell/bat.nix

    ./shell/aliases.nix

  ];

  home.packages = with pkgs; [
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
    ffmpeg
  ];







  home.stateVersion = "23.11";

}
