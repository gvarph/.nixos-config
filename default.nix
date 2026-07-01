{
  config,
  pkgs,
  username,
  inputs,
  ...
}: {
  imports = [
    # set locale
    ./linux/locale.nix

    # set up ssh server
    ./linux/features/ssh.nix

    ./linux/features/docker.nix

    # Set up age secret key
    ./secrets/age.nix
  ];

  # Enable flake support
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = ["networkmanager" "wheel" "nixeditors" "docker" "openvpn" "video" "render"];
    packages = [];
    shell = pkgs.fish;
    home = "/home/${username}";
    hashedPassword = "$6$nDwj1uS.gupSHUbz$c5Noj0SE.ala4h/sgfREH2TlBo92ry8EBaiCiGvsVyIqE7jlwIb4KtLHypjkYwwIawgGfy5H0KS7lpTyFa/QJ0";

    openssh.authorizedKeys.keys = import ./ssh_keys.nix;
  };

  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = {"vm.max_map_count" = 2147483642;};

  system.stateVersion = "23.11";

  # Nix home manager configuration
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;

  home-manager.users.${username} = {
    # home.enableNixpkgsReleaseCheck = false;

    imports = [
      # set user and enable home-manager
      (import ./home {inherit config pkgs inputs username;})
    ];
  };

  programs.fish.enable = true;

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
      "https://catppuccin.cachix.org"
    ];
    trusted-substituters = [
      "https://hyprland.cachix.org"
      "https://catppuccin.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
    ];
  };
}
