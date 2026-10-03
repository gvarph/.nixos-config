# Fitness MCP servers for Hermes (devices/nas1/fitness-mcp.nix); not in nixpkgs.
final: prev: {
  # Garmin Connect via python-garminconnect. No tagged release tracks main.
  garmin-mcp = prev.python3Packages.buildPythonApplication {
    pname = "garmin-mcp";
    version = "0.1.0-unstable-2026-10-01";
    pyproject = true;
    src = prev.fetchFromGitHub {
      owner = "taxuspt";
      repo = "garmin_mcp";
      rev = "cfc5d799ab0f165e837f1188a1d093c65838aaf7";
      hash = "sha256-ynW1rMzfSK3FqEnSNoU1jziJ8xQBKENP8GpT7edW50Q=";
    };
    build-system = [prev.python3Packages.hatchling];
    dependencies = with prev.python3Packages; [python-dotenv garminconnect requests mcp fitparse];
    # Exact pins upstream; nixpkgs has newer patch releases.
    pythonRelaxDeps = true;
    doCheck = false;
    meta.mainProgram = "garmin-mcp";
  };

  # Hevy via the published npm package (bundled dist); lockfile generated here.
  hevy-mcp = prev.buildNpmPackage {
    pname = "hevy-mcp";
    version = "6.1.19";
    src = ./hevy-mcp;
    npmDepsHash = "sha256-OJLwYWXDrK5QuB0sjR54qVVWIQyr013X/igZD7edGQc=";
    dontNpmBuild = true;
    installPhase = ''
      mkdir -p $out/lib $out/bin
      cp -r node_modules $out/lib/
      makeWrapper ${prev.nodejs}/bin/node $out/bin/hevy-mcp \
        --add-flags $out/lib/node_modules/hevy-mcp/dist/cli.mjs
    '';
    meta.mainProgram = "hevy-mcp";
  };
}
