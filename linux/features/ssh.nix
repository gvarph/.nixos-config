{ pkgs, ... }:

{

  environment.systemPackages = [ pkgs.openssh ];


  services.xserver = {
    layout = "us";
    xkbVariant = "";
    enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = true;
    };
    extraConfig = ''
      # external addressess
      Match Address 192.168.31.0/24
        PasswordAuthentication yes
    '';
  };

}
