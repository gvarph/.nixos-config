{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    ...
  } @ inputs: {
    # NixOS configuration for devices
    nixosConfigurations.serv1 = nixpkgs.lib.nixosSystem {
      specialArgs =
        inputs
        // {
          pkgs-stable = nixpkgs-stable.legacyPackages.${"x86_64-linux"};
        };
      modules = [
        inputs.sops-nix.nixosModules.sops
        inputs.home-manager.nixosModules.default
        ./devices/serv1
        ./sops.nix
      ];
    };

    # Home manager only configuration
    homeConfigurations.gvarph = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = {
        username = "gvarph"; # Or whatever username you want to use
      };
      modules = [
        ./home
        {
          # Add this configuration to allow unfree packages
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
  };
}
