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

  # User password lives in an agenix secret so the hash isn't world-readable
  # via the nix store / git. To change it: mkpasswd -m sha-512, then re-encrypt
  # with agenix -e gvarph_password.age (recipients in secrets/secrets.nix).
  age.secrets.gvarph_password.file = ./secrets/gvarph_password.age;

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = ["networkmanager" "wheel" "nixeditors" "docker" "openvpn" "video" "render"];
    packages = [];
    shell = pkgs.fish;
    home = "/home/${username}";
    hashedPasswordFile = config.age.secrets.gvarph_password.path;

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
    max-jobs = "auto";
    cores = 0;

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
