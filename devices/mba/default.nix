{
  self,
  lib,
  pkgs,
  inputs,
  config,
  ...
}: let
  username = "gvarph";
in {
  nixpkgs.config.allowUnfree = true;

  # We use Homebrew to install impure software only (Mac Apps)
  homebrew.enable = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.${username} = {
    imports = [
      (import ../../home {inherit config pkgs username inputs;})
    ];
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

  nix.enable = true;
  system.primaryUser = "gvarph";

  programs.fish.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 5;

  nixpkgs.hostPlatform = "x86_64-darwin";
}
