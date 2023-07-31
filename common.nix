# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      # fix vs code server
      #./system/vscode-server.nix

      # set locale
      ./system/locale.nix

      # set user and enable home-manager
      ./user/users.nix

      # set up ssh server
      ./system/features/ssh.nix

      ./system/features/direnv.nix

      ./system/fonts.nix
    ];


  # Enable flake support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #cd List packages installed in system profile.
  environment.systemPackages = with pkgs; [
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

  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };


  system.stateVersion = "23.05"; # Did you read the comment
}
