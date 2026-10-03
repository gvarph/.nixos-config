# VictoriaMetrics/VictoriaLogs MCP servers: not in nixpkgs, built from pinned tags.
# Patched so the docs search index is prebuilt into $out and mmapped read-only
# (~35 MiB RSS) instead of rebuilt in RAM by every process (~465 / ~86 MiB).
final: prev: let
  vmMcp = {
    pname,
    version,
    hash,
    entrypointVar,
    extraLdflags ? [],
  }:
    prev.buildGoModule {
      inherit pname version;
      src = prev.fetchFromGitHub {
        owner = "VictoriaMetrics";
        repo = pname;
        tag = "v${version}";
        inherit hash;
      };
      vendorHash = null; # dependencies are vendored upstream
      patches = [./patches/${pname}-docs-index-on-disk.patch];
      subPackages = ["cmd/${pname}"];
      ldflags =
        ["-s" "-w" "-X github.com/VictoriaMetrics/${pname}/cmd/${pname}/resources.IndexDir=${placeholder "out"}/share/${pname}/docs-index"]
        ++ extraLdflags;
      doCheck = false;
      # Startup builds the missing index; stdio mode then exits on EOF.
      postInstall = ''
        ${entrypointVar}=http://127.0.0.1:1 $out/bin/${pname} </dev/null
        test -f $out/share/${pname}/docs-index/index_meta.json
      '';
      meta.mainProgram = pname;
    };
in {
  mcp-victorialogs = vmMcp {
    pname = "mcp-victorialogs";
    version = "1.9.0";
    hash = "sha256-esfd6Eg1j2BCgee1T5tiIdSPWVEBqhI4UGDKRFYyn3s=";
    entrypointVar = "VL_INSTANCE_ENTRYPOINT";
  };

  mcp-victoriametrics = vmMcp rec {
    pname = "mcp-victoriametrics";
    version = "1.20.2";
    hash = "sha256-7kN7qwsvTL0scfBxMO/nrvikiysUxPY8nSFkhJsgGDM=";
    entrypointVar = "VM_INSTANCE_TYPE=single VM_INSTANCE_ENTRYPOINT";
    extraLdflags = ["-X main.version=${version}"];
  };
}
