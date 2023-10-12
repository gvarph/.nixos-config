{
  description = "Desktop configuration using flakes";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        modules = [
          ./default.nix
          /etc/nixos/hardware-configuration.nix
        ];
      };
    };
  };
}
