{ config, pkgs, username, ... }:

let
  secrets = import /etc/nixos/secrets.nix;
in
{
  imports =
    [
      # fix vs code server
      ./linux/vscode-server.nix

      # set locale
      ./linux/locale.nix

      # set user and enable home-manager
      (import ./home/users.nix { inherit config pkgs username; })

      # set up ssh server
      ./linux/features/ssh.nix

      ./linux/features/direnv.nix

      ./linux/fonts.nix
    ];


  # Enable flake support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;




  users.users.${username} = {

    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = [ "networkmanager" "wheel" "nixeditors" "docker" "openvpn" ];
    packages = with pkgs;
      [ ];
    shell = pkgs.fish;
    home = "/home/${username}";
    openssh.authorizedKeys.keys = secrets.authorizedSSHKeys;
    hashedPassword = secrets.hashedPassword;
  };


  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };


  system.stateVersion = "23.11";
}
