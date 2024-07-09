{
  pkgs,
  pkgs-unstable,
  ...
}: {
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix

    ./shell/eza.nix
    ./shell/bat.nix

    ./shell/aliases.nix

    ./programs/nvim
    ./programs/tmux

    ./stable.nix
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
    # neofetch
    tree
    ffmpeg
    # thefuck
    k9s
    # basedpyright

    (
      google-cloud-sdk.withExtraComponents
      (with pkgs.google-cloud-sdk.components; [
        gke-gcloud-auth-plugin
      ])
    )

    skaffold
    minikube
    kubectl

    # azure-cli

    busybox

    wget
    curl

    openssh

    git
    git-crypt
    nixpkgs-fmt
    gdu
    grc
  ];

  home.stateVersion = "23.11";
}
