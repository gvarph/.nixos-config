# awakened-poe-trade: run the upstream AppImage with its bundled Electron
# instead of nixpkgs' build, which re-wraps app.asar on the system `electron`.
# APT 3.29.x ships Electron 40; on Electron 44+ its clipboard handling breaks
# (price check copies the item but never opens the popup):
# https://github.com/SnosMe/awakened-poe-trade/issues/1970
# Pinning nixpkgs' electron_40 instead would need permittedInsecurePackages
# (EOL), whereas the AppImage is exactly what upstream tests.
#
# It must also run under XWayland, not native Wayland — its input engine
# (libuiohook) is X11-only. The AppImage's AppRun normally injects
# --ozone-platform=x11, but wrapType2 bypasses AppRun, so pass it here.
# Electron 39+ ignores ELECTRON_OZONE_PLATFORM_HINT:
# https://github.com/SnosMe/awakened-poe-trade/issues/1647
# --force-device-scale-factor=1 is a separate 4K sizing choice.
#
# Consumed via pkgs.awakened-poe-trade by devices/desktop (systemPackages) and
# by the with-apt wrapper in linux/features/gaming.nix, hence an overlay rather
# than a local package definition.
final: prev: let
  inherit (prev.awakened-poe-trade) pname version src;
  contents = prev.awakened-poe-trade.passthru.appImageContents;
in {
  awakened-poe-trade = final.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs = p: [p.libxtst p.libxt];
    nativeBuildInputs = [final.makeWrapper];
    extraInstallCommands = ''
      wrapProgram $out/bin/awakened-poe-trade \
        --set XDG_SESSION_TYPE x11 \
        --add-flags "--ozone-platform=x11 --force-device-scale-factor=1"
      install -Dm444 ${contents}/awakened-poe-trade.desktop \
        $out/share/applications/awakened-poe-trade.desktop
      substituteInPlace $out/share/applications/awakened-poe-trade.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=awakened-poe-trade'
      cp -r ${contents}/usr/share/icons $out/share/
    '';
    meta = prev.awakened-poe-trade.meta;
  };
}
