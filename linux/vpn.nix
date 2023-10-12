{ ... }:

let
  secrets = import /etc/nixos/secrets.nix;
in
{
  services.openvpn.servers = {
    officeVPN = {
      config = '' config /etc/nixos/secrets/bizmachine_new.ovpn '';
      authUserPass.username = secrets.office-vpn-login.username;
      authUserPass.password = secrets.office-vpn-login.password;
      autoStart = false;
    };
  };
}
