{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Stable nixpkgs for Azure CLI
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

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

    # Don't make nixpkgs follow ours: catppuccin's binary cache
    # (catppuccin.cachix.org) only has whiskers built against its own pinned
    # nixpkgs, so following ours forces a local rebuild every update.
    catppuccin = {
      url = "git+https://github.com/catppuccin/nix.git";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code.url = "github:sadjow/claude-code-nix";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    # Bleeding-edge packages (mesa_git): works around a Mesa 26.1.5 RADV
    # builtin-shader-cache flock self-deadlock that black-screens games and
    # hangs gamescope on the desktop.
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = {
    self,
    agenix,
    catppuccin,
    claude-code,
    disko,
    home-manager,
    hyprland,
    nix-darwin,
    nixpkgs,
    nixpkgs-stable,
    ...
  } @ inputs: let
    # Define all overlays in one place
    overlays = [
      # Azure CLI
      (final: prev: {
        azure-cli = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.azure-cli;
        azure-cli-extensions = inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.azure-cli-extensions;
      })
      # Zen browser
      (final: prev: {
        zen-browser = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system}.default;
      })
      # debugpy: pin to stable AND skip its test suite. debugpy's build runs a
      # heavy pytestCheckPhase that regularly hangs for 15+ min in teardown
      # (lingering debug-adapter subprocesses / gevent greenlets waiting on
      # socket timeouts) — which is why cache.nixos.org / Hydra often lacks a
      # prebuilt debugpy, forcing a from-source rebuild on nearly every flake
      # bump. Pinning to stable alone isn't enough: right after a stable channel
      # bump the new debugpy isn't cached either, so it still builds from source
      # and hangs. Since this is just the DAP adapter binary (the exact version
      # doesn't matter and we don't ship its tests), disable doCheck so the build
      # is a fast, deterministic Cython compile regardless of cache state.
      (final: prev: {
        python312Packages =
          prev.python312Packages
          // {
            debugpy =
              (inputs.nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.python312Packages.debugpy)
              .overridePythonAttrs (_: {doCheck = false;});
          };
      })

      # mongodb-compass: nixos-unstable's build is currently broken (patchelf/
      # wrapGAppsHook chokes on bundled non-ELF binaries in the Electron app).
      # Pin to stable until upstream fixes it. mongodb-compass is unfree, so
      # this needs its own nixpkgs instantiation with allowUnfree set —
      # nixpkgs-stable.legacyPackages doesn't inherit our nixpkgs.config.
      (final: prev: {
        mongodb-compass =
          (import inputs.nixpkgs-stable {
            system = final.stdenv.hostPlatform.system;
            config.allowUnfree = true;
          })
          .mongodb-compass;
      })

      claude-code.overlays.default

      # CachyOS kernel packages (exposes pkgs.cachyosKernels.*)
      inputs.nix-cachyos-kernel.overlays.pinned
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
          catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          disko.nixosModules.disko
          ./devices/${hostname}
          {
            nixpkgs.overlays = overlays;
            home-manager.users.gvarph.imports = [catppuccin.homeModules.catppuccin];
            catppuccin.enable = true;
            catppuccin.autoEnable = true;
          }
        ];
      };
  in {
    nixosConfigurations = {
      desktop = mkNixos "desktop";
      serv1 = mkNixos "serv1";
      nas1 = mkNixos "nas1";
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
          home-manager.users.gvarph.imports = [catppuccin.homeModules.catppuccin];
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
          packages = [
            pkgs.alejandra # Nix formatter
            pkgs.disko
            pkgs.nh
            agenix.packages.${system}.default # Agenix CLI tool
            disko.packages.${system}.disko
          ];
        };
      });
  };
}
