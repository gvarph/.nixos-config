{ pkgs, ... }:

{

  environment.systemPackages = [ pkgs.openssh ];


  # Configure X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
    enable = true;
  };

  services.openssh = {
    enable = true; # enable ssh server
    settings.PermitRootLogin = "no"; # prevent root login via ssh
    settings.PasswordAuthentication = false; # allow only key based authentication
    settings.X11Forwarding = true; #enable x11 forwarding
  };


}
