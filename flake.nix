{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-main.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    agenix,
    ...
  } @ inputs: let
    opencodeOverlay = final: prev: {
      opencode = inputs.nixpkgs-main.legacyPackages.${final.system}.opencode;
    };
  in {
    # sudo nixos-rebuild switch --flake .#serv1
    nixosConfigurations.serv1 = nixpkgs.lib.nixosSystem {
      specialArgs =
        inputs
        // {
          age = agenix.packages."x86_64-linux".default;
        };
      modules = [
        inputs.home-manager.nixosModules.default
        inputs.agenix.nixosModules.default
        ./devices/serv1
        {nixpkgs.overlays = [opencodeOverlay];}
      ];
    };

    nixosConfigurations.serv2 = nixpkgs.lib.nixosSystem {
      specialArgs =
        inputs
        // {
          age = agenix.packages."x86_64-linux".default;
        };
      modules = [
        inputs.home-manager.nixosModules.default
        inputs.agenix.nixosModules.default
        ./devices/serv2
      ];
    };

    # home-manager switch --flake .#wsl
    homeConfigurations.wsl = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      extraSpecialArgs = {
        username = "gvarph";
      };
      modules = [
        ./home
        {
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };

    #darwin-rebuild switch --flake .#mba --show-trace
    darwinConfigurations."mba" = nix-darwin.lib.darwinSystem {
      specialArgs =
        inputs
        // {
        };

      modules = [
        ./devices/mba
        home-manager.darwinModules.home-manager
      ];
    };

    darwinPackages = self.darwinConfigurations."mba".pkgs;

    # Development shells
    devShells =
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ] (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          name = "nix-config";
          packages = with pkgs; [
            alejandra # Nix formatter
            nil # Nix language server
            agenix.packages.${system}.default # Agenix CLI tool
          ];
        };
      });
  };
}
