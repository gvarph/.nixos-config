# mcp-victorialogs for Claude Code on nas1 (home/mcp/victorialogs.nix): not in
# nixpkgs and only shipped as a Go module, binary or container, so it is built
# from the pinned upstream tag.
final: prev: {
  mcp-victorialogs = prev.buildGoModule rec {
    pname = "mcp-victorialogs";
    version = "1.9.0";
    src = prev.fetchFromGitHub {
      owner = "VictoriaMetrics";
      repo = "mcp-victorialogs";
      tag = "v${version}";
      hash = "sha256-esfd6Eg1j2BCgee1T5tiIdSPWVEBqhI4UGDKRFYyn3s=";
    };
    vendorHash = null; # dependencies are vendored upstream
    subPackages = ["cmd/mcp-victorialogs"];
    ldflags = ["-s" "-w"];
    doCheck = false;
    meta.mainProgram = "mcp-victorialogs";
  };
}
