{
  config,
  pkgs,
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
    # "${fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master"}/modules/vscode-server/home.nix"
  ];

  home.packages = with pkgs; [
    alejandra
    # vscode
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

    #azure-cli

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
