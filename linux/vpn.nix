{ ... }:

{
  services.openvpn.servers = {
    officeVPN = {
      config = '' config /run/secrets/bizmachine_vpn.ovpn '';

      authUserPass.username = "filip.krul";
      authUserPass.password = "98f_pK2710C!";

      autoStart = true;
    };
  };
}
