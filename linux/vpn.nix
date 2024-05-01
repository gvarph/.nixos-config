{ ... }:

{
  services.openvpn.servers = {
    officeVPN = {
      config = '' config /run/secrets/bizmachine_vpn.ovpn '';

      authUserPass.username = "filip.krul";
      authUserPass.password = "foo";

      autoStart = true;
    };
  };
}
