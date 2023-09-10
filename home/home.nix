{ config, pkgs, ... }:

{
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix

    ./shell/eza.nix
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

    google-cloud-sdk
    skaffold
    minikube
    kubectl

    azure-cli

    wget
    curl
    tmux
    openssh
    rnix-lsp
    git
    git-crypt
    nixpkgs-fmt
    gdu
    grc
  ];


  home.stateVersion = "23.11";

}
