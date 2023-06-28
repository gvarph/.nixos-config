# .nixos-config

To enable this config, replace the contents of your `configuration.nix` with the following:

```nix
{ config, pkgs, ... }:

{
  imports = [
      ./hardware-configuration.nix
      /home/gvarph/.nixos-config/configuration.nix
    ];
}
```