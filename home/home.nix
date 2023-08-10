{ config, pkgs, ... }:

{
  imports = [
    ./shell/fish.nix

    ./shell/starship.nix

    ./shell/exa.nix
    ./shell/bat.nix

    ./shell/aliases.nix
    "${fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/master"}/modules/vscode-server/home.nix"
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
  services.vscode-server.enable = true;


  home.stateVersion = "23.11";

}
