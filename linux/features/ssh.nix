{pkgs, ...}: {
  environment.systemPackages = [pkgs.openssh];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
      X11Forwarding = true;
    };
  };

  #services.fail2ban.enable = true;
}
