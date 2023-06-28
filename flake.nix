{
  description = "Gvarph's collection of dev environments and packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    }:

    let
      # Conveniences for Nixpkgs
      overlays = [
        (self: super: {
          nodejs = super.nodejs-18_x;
          pnpm = super.nodePackages.pnpm;
          alex = super.nodePackages.alex;
        })
      ];

      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });

      # Helper function for scripting
      runPkg = pkgs: pkg: "${pkgs.${pkg}}/bin/${pkg}";
    in
    {
      devShells = forAllSystems
        ({ pkgs }:
          let
            common = with pkgs; [
              # CI
              cachix
              direnv
              nix-direnv

              # Language
              vale
              alex

              # Link checking
              htmltest

              # JS
              nodejs
              pnpm
            ];

            run = pkg: runPkg pkgs pkg;

            scripts = with pkgs; [
              (writeScriptBin "clean" ''
                rm -rf dist
              '')

              (writeScriptBin "setup" ''
                clean
                ${run "pnpm"} install
              '')

              (writeScriptBin "build" ''
                setup
                ${run "pnpm"} run build
              '')

              (writeScriptBin "build-ci" ''
                setup
                ENV=ci ${run "pnpm"} run build
              '')

              (writeScriptBin "dev" ''
                setup
                ${run "pnpm"} run dev
              '')

              (writeScriptBin "format" ''
                setup
                ${run "pnpm"} run format
              '')

              (writeScriptBin "check-internal-links" ''
                ${run "htmltest"} --conf ./.htmltest.internal.yml
              '')

              (writeScriptBin "check-external-links" ''
                ${run "htmltest"} --conf ./.htmltest.external.yml
              '')

              (writeScriptBin "lint-style" ''
                ${run "vale"} src/pages
              '')

              (writeScriptBin "check-sensitivity" ''
                ${run "alex"} --quiet src/pages
              '')

              (writeScriptBin "check-types" ''
                ${run "pnpm"} run typecheck
              '')

              (writeScriptBin "preview" ''
                build
                ${run "pnpm"} run preview
              '')

              # Run this to see if CI will pass
              (writeScriptBin "ci" ''
                set -e
                build-ci
                check-internal-links
                lint-style
                check-sensitivity
                check-types
              '')
            ];

            exampleShells = import ./nix/shell/example.nix { inherit pkgs; };
          in
          {
            inherit (exampleShells) example cpp haskell hook javascript python go rust scala multi;
          } // {
            default = pkgs.mkShell
              {
                packages = common ++ scripts;
              };
          });

      apps = forAllSystems ({ pkgs }:
        let
          run = pkg: runPkg pkgs pkg;

          runLocal = pkgs.writeScriptBin "run-local" ''
            rm -rf dist
            ${run "pnpm"} install
            ${run "pnpm"} run build
            ${run "pnpm"} run preview
          '';
        in
        {
          default = {
            type = "app";
            program = "${runLocal}/bin/run-local";
          };
        });

      templates = {

        python-dev = {
          path = ./nix/templates/dev/python;
          description = "Python dev environment template";
        };


      };
    }
