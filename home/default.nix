{
  config,
  pkgs,
  username,
  inputs,
  ...
}: {
  home.username = username;

  programs.home-manager.enable = true;
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix

    ./shell/eza.nix
    ./shell/bat.nix

    ./shell/aliases.nix

    ./programs/nvim
    ./programs/tmux
    ./programs/direnv
    ./programs/git
    ./programs/zoxide.nix
    ./programs/az-cli

    ./programs/opencode
  ];

  programs.tealdeer = {
    enable = true;
    enableAutoUpdates = true;
  };

  programs.nh = {
    enable = true;
    flake = "/home/gvarph/.nixos-config/";
  };

  home.packages = with pkgs; [
    alejandra
    fd
    ripgrep
    tokei
    fzf
    procs
    prettyping
    gzip
    unzip
    htop
    bottom
    fastfetch
    tree
    ffmpeg
    k9s
    dust

    (
      google-cloud-sdk.withExtraComponents
      (with pkgs.google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ])
    )

    skaffold
    minikube
    kubectl

    wget
    curl

    openssh

    git-crypt
    nixpkgs-fmt
    gdu
    grc
  ];

  home.stateVersion = "23.11";
}
