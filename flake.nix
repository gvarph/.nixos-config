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

    # Podman quadlets as NixOS options; imported per host (devices/nas1/podman.nix).
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    # Hermes agent: upstream NixOS module + package, pinned to a release tag.
    # Not following nixpkgs: its uv2nix Python env is locked against upstream's own.
    hermes-agent.url = "github:NousResearch/hermes-agent/v2026.9.24";

    # Tracks main. Only main revs build here, because hyprland.cachix.org serves
    # them prebuilt. Tagged releases don't build locally: CMakeLists wants
    # `glaze 7...<8`, nixpkgs ships glaze 8, and the FetchContent fallback is
    # blocked by the sandbox. If a local build ever gets attempted, switch to
    # nixpkgs' own hyprland (see devices/desktop/default.nix), which patches
    # the glaze bound and lives in cache.nixos.org.
    hyprland.url = "github:hyprwm/Hyprland";

    # Waybar from master, because Hyprland main changes its IPC faster than
    # waybar releases keep up. Needed for workspace clicks under
    # configProvider = "lua", where `hyprctl dispatch` wraps hl.dispatch() and
    # the legacy strings 0.15.0 sends are invalid Lua (fixed in
    # https://github.com/Alexays/Waybar/pull/5013). The overlay is upstream's
    # own: nixpkgs' waybar derivation with the master source swapped in.
    # Drop this input and its overlay once a waybar release catches up.
    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      (import ./overlays/mcp-servers.nix)
      (import ./overlays/crowdsec-lua-bouncer.nix)

      # waybar built from master, see the input above.
      inputs.waybar.overlays.default

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
