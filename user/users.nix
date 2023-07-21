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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDLHO/mS3CxMS6TieqaFEqPcP1uJcgkGYBcINY9GceosG4Wyx+q1Y/K2bt+VDjM2cap7Y7njdNMDK2F+G2o8T/Oihhi7qk/kGgavOsTXp0XSQqzvaE0yeE3uGUAE4c+WMCGi97gd8R3robQSl6UlrzGcKIaqVJeZAO1Vs5trbX0yjnmGtiXcUAdZvw5bBxNmp49UVBylJjXCQd+y/neqeP3JVuEiEeLubqFBQEE5p5XVYm5YqA+dfvysQR9sNC5tPurpDCPljxQol6EYmCAoWOTyJ9oe4Ps7IXnpMy+lfaw3Sfl7Z+r0+FqLSnt2U4j92NNDTSnQRcysF3mcqacHPKptSidcCKF2JYJPfx/mYdxrCFq5ajA4iIy+L7tpVa/5paLolrvb1vgYDWd3eWpQqPNifPR3IYHFebWs6jH3J5sNoI5qd44S0k9vN47yztrn9UdTpdxj3G4USDdleMs7Ukp9q+gGacvNi37etulBB0BNj1XB3Pc8cNHWeF7MIvxGh8= gvarp@Gvarph_D"
    ];
    hashedPassword = "$6$ajl7nqlQ56pQjV.t$/sx/BEf0I9.V2cpuKzmxnFJeu7pmB5.Doe6CmJx25Di//giCM1hyz4GfkS6LSv5JrcyyEcWYbd9LmrMsJ6ZSW/";
  };


}
