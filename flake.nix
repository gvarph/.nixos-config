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

    # Pinned rather than tracking the default branch. Untagged main ships
    # breaking IPC changes that outpace downstream consumers:
    #
    #   - Hyprland#16140 removed workspace ids from the hyprctl JSON and the
    #     socket2 *v2 event payloads in favour of "addressables". That breaks
    #     waybar's hyprland/workspaces module, which reads workspace["id"] and
    #     gets 0 for every workspace, so every monitor shows a single button
    #     labelled "0". See https://github.com/hyprwm/Hyprland/pull/16140 and
    #     the waybar side at https://github.com/Alexays/Waybar/issues/5316
    #   - The same drift previously broke workspace clicks, see the overlay
    #     below and https://github.com/Alexays/Waybar/pull/5013
    #
    # 7ebf13a is the last commit before #16140 merged (as e9e2f64, 2026-09-09).
    # Verified on it: workspace JSON still has "id", the *v2 events still carry
    # the numeric id, and `dispatch` is still the Lua wrapper the overlay below
    # depends on.
    #
    # Why a commit and not the v0.56.2 tag: no flake rev of Hyprland builds
    # locally right now. CMakeLists wants `glaze 7...<8`, nixpkgs ships glaze 8,
    # so find_package misses and it falls back to a FetchContent git clone that
    # the build sandbox blocks. Main revs only work because hyprland.cachix.org
    # serves them prebuilt -- and this commit is in that cache, whereas the tag
    # is not.
    #
    # If that cache entry is ever GC'd and a local build gets attempted, switch
    # to nixpkgs' own hyprland (see devices/desktop/default.nix): it is also
    # 0.56.2, patches the glaze bound via postPatch, and lives in
    # cache.nixos.org. That drops this input entirely.
    #
    # To revisit: once Waybar#5316 ships in a waybar release, this can go back
    # to tracking main.
    hyprland = {url = "github:hyprwm/Hyprland/7ebf13abb3c391604c60c9f627c7a403bcec8d17";};

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
  };

  outputs = {
    self,
    agenix,
    catppuccin,
    claude-code,
    disko,
    home-manager,
    nix-darwin,
    nixpkgs,
    ...
  } @ inputs: let
    # Define all overlays in one place
    overlays = [
      (import ./overlays/awakened-poe-trade.nix)

      # waybar: workspace clicks are no-ops when Hyprland's configProvider is
      # "lua" (check with `hyprctl systeminfo | grep configProvider`), because
      # `hyprctl dispatch <x>` is then a wrapper for `hl.dispatch(<x>)` and the
      # legacy string waybar sends is not valid Lua. Still required on the
      # v0.56.2 pin above -- the behaviour keys off the config provider, not the
      # Hyprland version, and this config is Lua.
      #
      # Fixed upstream in https://github.com/Alexays/Waybar/pull/5013 (unreleased
      # as of waybar 0.15.0); master now auto-detects via configProvider. Drop
      # this overlay once that lands in a waybar release.
      (final: prev: {
        waybar = prev.waybar.overrideAttrs (old: {
          patches = (old.patches or []) ++ [./home/ui/wayland/waybar/hyprland-lua-dispatch.patch];
        });
      })

      claude-code.overlays.default

      # CachyOS kernel packages (exposes pkgs.cachyosKernels.*)
      inputs.nix-cachyos-kernel.overlays.pinned
    ];

    # Helper to create NixOS configurations
    mkNixos = hostname:
      nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;};
        modules = [
          home-manager.nixosModules.default
          catppuccin.nixosModules.catppuccin
          agenix.nixosModules.default
          disko.nixosModules.disko
          ./devices/${hostname}
          {
            nixpkgs.overlays = overlays;
            home-manager.extraSpecialArgs = {inherit inputs;};
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
      specialArgs = inputs;

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
            pkgs.nh
            agenix.packages.${system}.default # Agenix CLI tool
            disko.packages.${system}.disko
          ];
        };
      });
  };
}
