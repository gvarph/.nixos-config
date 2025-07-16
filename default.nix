{
  config,
  pkgs,
  username,
  inputs,
  ...
}: {
  imports = [
    # fix vs code server
    ./linux/vscode-server.nix

    # set locale
    ./linux/locale.nix

    # set up ssh server
    ./linux/features/ssh.nix

    #./linux/fonts.nix
  ];

  # Enable flake support
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.mutableUsers = false;
  users.users.${username} = {
    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = ["networkmanager" "wheel" "nixeditors" "docker" "openvpn"];
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
}
