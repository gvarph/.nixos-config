{ pkgs, inputs, config, username, ... }:
{
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    age = {
      keyFile = "/home/gvarph/.config/sops/age/keys.txt";
    };

    secrets = {
      "nas-credentials" = { };



      "bizmachine_vpn.credentials" = { };
      "bizmachine_vpn.ovpn" = { };

      hashedPassword = {
        neededForUsers = true;
      };
    };
  };
}
