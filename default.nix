{ config, pkgs, username, ... }:

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
    extraGroups = [ "networkmanager" "wheel" "nixeditors" "docker" ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
    home = "/home/${username}";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLHO/mS3CxMS6TieqaFEqPcP1uJcgkGYBcINY9GceosG4Wyx+q1Y/K2bt+VDjM2cap7Y7njdNMDK2F+G2o8T/Oihhi7qk/kGgavOsTXp0XSQqzvaE0yeE3uGUAE4c+WMCGi97gd8R3robQSl6UlrzGcKIaqVJeZAO1Vs5trbX0yjnmGtiXcUAdZvw5bBxNmp49UVBylJjXCQd+y/neqeP3JVuEiEeLubqFBQEE5p5XVYm5YqA+dfvysQR9sNC5tPurpDCPljxQol6EYmCAoWOTyJ9oe4Ps7IXnpMy+lfaw3Sfl7Z+r0+FqLSnt2U4j92NNDTSnQRcysF3mcqacHPKptSidcCKF2JYJPfx/mYdxrCFq5ajA4iIy+L7tpVa/5paLolrvb1vgYDWd3eWpQqPNifPR3IYHFebWs6jH3J5sNoI5qd44S0k9vN47yztrn9UdTpdxj3G4USDdleMs7Ukp9q+gGacvNi37etulBB0BNj1XB3Pc8cNHWeF7MIvxGh8= gvarp@Gvarph_D"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxQd1E2P6RVXJRBxMcV/Zmm683vLxpkfxPgvkYyBTmhYtohvMBs9DFxDsr5ual/kWb5UCv8Ae80GS3V1bXH4lrm05hcP3FJA1UCUpQ9GQZMjjp6F72GcXcdjXmf98eWZE1+V3xWd206n9GjZbo2edErON7TqwWBPMfo6RSJlSvo3lrksN6/5V9Ja/ZdhLK0uCehWEwavlG1BfUMhLqeXBJEu2N4+OG2DqNkThc7pMyg/Yiwn2vQl03H4C0R6ZnNOagJ07hFit41073gvyUqQeGGVyoYq0PW9WbmQTb9u3F2lWre052y3uv+EruhsEXBCSQELyZE6DWtfy/Tzr7fCF7xSdlAkOTjsGaSkpUbjx71HKbWDM251oe8BzUIy4u4QPOJjTzc1CPz3kEsdCnI0WoYnb036iwty/pxmWJsI5b1n+9fiAEs8wDauSjdpeTR7TkqgSaIbAbkg5ZelqTvQcOEnHkYoE4hYclSZQXUQHhXMfmE0zaxlkZE62ex0vXgi0= user@DESKTOP-A3LQ8JG  "

    ];
    hashedPassword = "$6$ajl7nqlQ56pQjV.t$/sx/BEf0I9.V2cpuKzmxnFJeu7pmB5.Doe6CmJx25Di//giCM1hyz4GfkS6LSv5JrcyyEcWYbd9LmrMsJ6ZSW/";
  };


  programs.nix-ld.enable = true;

  # may break 16-bit apps
  boot.kernel.sysctl = { "vm.max_map_count" = 2147483642; };


  system.stateVersion = "unstable";
}
