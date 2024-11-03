{
  self,
  lib,
  pkgs,
  pkgs-stable,
  inputs,
  config,
  ...
}: let
  username = "gvarph";
in {
  nixpkgs.config.allowUnfree = true;

  # We use Homebrew to install impure software only (Mac Apps)
  homebrew.enable = true;
  homebrew.brewPrefix = "/opt/homebrew/bin";

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = {
    imports = [
      (import ../../home {inherit config pkgs pkgs-stable username inputs;})
    ];

    programs.git = {
      enable = true;
      userName = "Filip Krul";
      userEmail = "gvarph006@gmail.com";
    };
  };

  users.users.${username} = {
    description = "Filip Krul";
    shell = pkgs.fish;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = [
    ];
  };
  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = [
    pkgs.unixODBC
    pkgs.fish
    # pkgs.unixODBCDrivers.msodbcsql17
  ];

  services.nix-daemon.enable = true;

  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "x86_64-darwin";
}
