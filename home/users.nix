{ config, pkgs, username, ... }:
{
  imports =
    [
      # load home-manager configuration
      <home-manager/nixos>
    ];


  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.${username} =
    {
      imports = [
        ./home.nix
      ];
      programs.git = {
        enable = true;
        userName = "Filip Krul";
        userEmail = "gvarph006@gmail.com";
      };
    };

  programs.fish.enable = true;
}
