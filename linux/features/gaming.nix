# Gaming-related configuration (gamescope, gamemode, MangoHud).
# Currently imported only by the desktop host.
{pkgs, ...}: {
  # Steam's gamescope micro-compositor session.
  # (Merges with the main programs.steam block in the host config.)
  programs.steam.gamescopeSession.enable = true;

  # Feral GameMode: system-level tuning (CPU governor, scheduling) while a
  # game runs. Activate per-game with `gamemoderun %command%` in Steam.
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    gamescope-wsi # HDR won't work without this
    mangohud # FPS/temp/usage overlay; run with `mangohud %command%`
  ];
}
