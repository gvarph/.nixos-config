{ config, pkgs, ... }:
{
  imports =
    [
      # load home-manager configuration
      <home-manager/nixos>
    ];


  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.gvarph = { pkgs, ... }:
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

  # Define a user account. Don't forget to set a password with ‘passwd’.

  programs.fish.enable = true;
  users.users.gvarph = {

    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = [ "networkmanager" "wheel" "nixeditors" "docker" ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
    home = "/home/gvarph";
  };


}
