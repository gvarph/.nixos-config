# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix

      # use device specific configuration
      ./system/devices/serv1.nix

      # fix vs code server
      ./system/vscode-server.nix

      # set locale
      ./system/locale.nix

      # set user and enable home-manager
      ./user/users.nix

      # set up ssh server
      ./system/ssh.nix
    ];


  # Enable flake support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    curl
    tmux
    openssh
    direnv
    rnix-lsp
    git
    git-crypt
    nixpkgs-fmt
  ];

  system.stateVersion = "23.05"; # Did you read the comment
}
