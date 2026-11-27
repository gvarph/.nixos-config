# steamvr-exporter: pushes SteamVR frame timing and Steam Link stream health
# to VictoriaMetrics (see steamvr-exporter/exporter.py).
# pyopenvr is not in nixpkgs; its wheel bundles libopenvr_api_64.so, which
# only links glibc and loads SteamVR's own vrclient.so at runtime.
final: prev: let
  pyopenvr = final.python3Packages.buildPythonPackage rec {
    pname = "openvr";
    version = "2.12.1401";
    format = "wheel";
    src = prev.fetchurl {
      url = "https://files.pythonhosted.org/packages/py3/o/openvr/openvr-${version}-py3-none-any.whl";
      sha256 = "ef761cef3162843a8025a7812d5e244fd94ab3a992ca8f5ef0d1b0188ad56cb3";
    };
    pythonImportsCheck = ["openvr"];
  };
  python = final.python3.withPackages (ps: [pyopenvr ps.prometheus-client]);
in {
  steamvr-exporter = final.writeShellApplication {
    name = "steamvr-exporter";
    text = ''exec ${python}/bin/python3 -I ${./steamvr-exporter/exporter.py} "$@"'';
  };
}
