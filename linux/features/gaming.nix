# Gamescope-related configuration.
# Currently imported only by the desktop host.
{pkgs, ...}: {
  # Steam's gamescope micro-compositor session.
  # (Merges with the main programs.steam block in the host config.)
  programs.steam.gamescopeSession.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    gamescope-wsi # HDR won't work without this
  ];
}
