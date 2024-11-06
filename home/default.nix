{
  config,
  pkgs,
  pkgs-stable,
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
    (import ./programs/az-cli {inherit pkgs-stable;})
  ];
  home.packages = with pkgs; [
    alejandra
    sops
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
    fastfetch
    tree
    ffmpeg
    thefuck
    k9s

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
