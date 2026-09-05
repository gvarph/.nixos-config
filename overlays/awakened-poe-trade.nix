# awakened-poe-trade: must run under XWayland, not native Wayland — its input
# engine (libuiohook) is X11-only, so global hotkeys, item copying, and
# game-window tracking all break as a Wayland client. Upstream recommends
# XDG_SESSION_TYPE=x11 for just this app (Electron 39+ ignores
# ELECTRON_OZONE_PLATFORM_HINT):
# https://github.com/SnosMe/awakened-poe-trade/issues/1647
#
# Status: upstream closed that issue and 3.28.104 "runs as X11 out of the box",
# so the two x11 settings below are likely redundant now (nixpkgs is on
# 3.29.104). --force-device-scale-factor=1 is a separate 4K sizing choice, not
# part of the upstream fix. Test in-game (hotkeys, item copy, window tracking,
# overlay size) before dropping this.
#
# Consumed via pkgs.awakened-poe-trade by devices/desktop (systemPackages) and
# by the with-apt wrapper in linux/features/gaming.nix, hence an overlay rather
# than a local package definition.
final: prev: {
  awakened-poe-trade = final.symlinkJoin {
    name = "awakened-poe-trade-xwayland";
    paths = [prev.awakened-poe-trade];
    nativeBuildInputs = [final.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/awakened-poe-trade \
        --set XDG_SESSION_TYPE x11 \
        --add-flags "--ozone-platform=x11 --force-device-scale-factor=1"
    '';
  };
}
