# Frame Control: desktop companion app for the Valve Steam Frame headset.
# Not in nixpkgs; wraps the upstream x86_64 AppImage release.
# To bump: change `version`, take the AppImage line from the release's
# SHA256SUMS, and convert it with `nix hash convert --to sri --hash-algo sha256`.
final: prev: let
  pname = "frame-control";
  version = "0.4.62";
  src = prev.fetchurl {
    url = "https://github.com/saphid/frame-control/releases/download/v${version}/Frame-Control-linux-x86_64.AppImage";
    hash = "sha256-/RV3XTQyXbD7t7QS4TWzjVLbZCx3kItkYeXH9ac4gio=";
  };
  contents = final.appimageTools.extractType2 {inherit pname version src;};
in {
  frame-control = final.appimageTools.wrapType2 {
    inherit pname version src;
    passthru.appImageContents = contents;
    # Electron app with its own bundled Python; it talks to the headset over
    # SSH, so make sure a client is inside the FHS env.
    extraPkgs = p: [p.openssh];
    extraInstallCommands = ''
      install -Dm444 ${contents}/frame-control.desktop \
        $out/share/applications/frame-control.desktop
      substituteInPlace $out/share/applications/frame-control.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=frame-control'
      cp -r ${contents}/usr/share/icons $out/share/
    '';
    meta = {
      description = "Companion app for the Valve Steam Frame headset";
      homepage = "https://github.com/saphid/frame-control";
      license = prev.lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "frame-control";
      sourceProvenance = [prev.lib.sourceTypes.binaryNativeCode];
    };
  };
}
