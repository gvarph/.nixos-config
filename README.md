# .nixos-config

To enable this config, replace the contents of your `configuration.nix` with the following:

```nix
{ config, pkgs, ... }:

{
  imports = [
        /home/gvarph/.nixos-config/devices/serv1.nix
        ./hardware-configuration.nix
    ];
}
```