{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Fixes a bug with non-linked c libraries
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # Stable nixpkgs for Azure CLI
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

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

    hyprland = {url = "github:hyprwm/Hyprland";};

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    #catppuccin.url = "github:catppuccin/nix";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    catppuccin,
    nix-darwin,
    hyprland,
    agenix,
    ...
  } @ inputs: let
    # Define all overlays in one place
    overlays = [
      # Opencode
      (final: prev: {
        opencode = inputs.nixpkgs-master.legacyPackages.${final.stdenv.hostPlatform.system}.opencode;
      })
      # Azure CLI
      (final: prev: {
        azure-cli = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.azure-cli;
        azure-cli-extensions = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.azure-cli-extensions;
      })
      # Zen browser
      (final: prev: {
        zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
      })
    ];

    # Helper to create NixOS configurations
    mkNixos = hostname:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          age = agenix.packages."x86_64-linux".default;
        };
        modules = [
          home-manager.nixosModules.default
          inputs.catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          ./devices/${hostname}
          {
            nixpkgs.overlays = overlays;
            home-manager.users.gvarph.imports = [inputs.catppuccin.homeModules.catppuccin];
            catppuccin.enable = true;
          }
        ];
      };
  in {
    nixosConfigurations = {
      desktop = mkNixos "desktop";
      serv1 = mkNixos "serv1";
      serv2 = mkNixos "serv2";
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
        {
          nixpkgs.overlays = overlays;
        }
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
