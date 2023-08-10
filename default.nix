# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, username, ... }:

{
  imports =
    [
      # fix vs code server
      ./system/vscode-server.nix

      # set locale
      ./system/locale.nix

      # set user and enable home-manager
      (import ./home/users.nix { inherit config pkgs username; })

      # set up ssh server
      ./system/features/ssh.nix

      ./system/features/direnv.nix

      ./system/fonts.nix
    ];


  # Enable flake support
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  #cd List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    #vscode
    wget
    curl
    tmux
    openssh
    rnix-lsp
    git
    git-crypt
    nixpkgs-fmt
    gdu
    grc
  ];



  users.users.${username} = {

    isNormalUser = true;
    description = "Filip Krul";
    extraGroups = [ "networkmanager" "wheel" "nixeditors" "docker" ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
    home = "/home/${username}";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLHO/mS3CxMS6TieqaFEqPcP1uJcgkGYBcINY9GceosG4Wyx+q1Y/K2bt+VDjM2cap7Y7njdNMDK2F+G2o8T/Oihhi7qk/kGgavOsTXp0XSQqzvaE0yeE3uGUAE4c+WMCGi97gd8R3robQSl6UlrzGcKIaqVJeZAO1Vs5trbX0yjnmGtiXcUAdZvw5bBxNmp49UVBylJjXCQd+y/neqeP3JVuEiEeLubqFBQEE5p5XVYm5YqA+dfvysQR9sNC5tPurpDCPljxQol6EYmCAoWOTyJ9oe4Ps7IXnpMy+lfaw3Sfl7Z+r0+FqLSnt2U4j92NNDTSnQRcysF3mcqacHPKptSidcCKF2JYJPfx/mYdxrCFq5ajA4iIy+L7tpVa/5paLolrvb1vgYDWd3eWpQqPNifPR3IYHFebWs6jH3J5sNoI5qd44S0k9vN47yztrn9UdTpdxj3G4USDdleMs7Ukp9q+gGacvNi37etulBB0BNj1XB3Pc8cNHWeF7MIvxGh8= gvarp@Gvarph_D"
    ];
    hashedPassword = "$6$ajl7nqlQ56pQjV.t$/sx/BEf0I9.V2cpuKzmxnFJeu7pmB5.Doe6CmJx25Di//giCM1hyz4GfkS6LSv5JrcyyEcWYbd9LmrMsJ6ZSW/";
  };


  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };


  system.stateVersion = "unstable";
}
