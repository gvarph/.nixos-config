{ config, pkgs, username, ... }:
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.${username} =
    {
      # home.enableNixpkgsReleaseCheck = false;

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
