# Gaming-related configuration (gamescope, gamemode, MangoHud).
# Currently imported only by the desktop host.
{pkgs, ...}: {
  # Steam's gamescope micro-compositor session.
  # (Merges with the main programs.steam block in the host config.)
  programs.steam.gamescopeSession.enable = true;

  # Feral GameMode: system-level tuning (CPU governor, scheduling) while a
  # game runs. Activate per-game with `gamemoderun %command%` in Steam.
  # GPU performance-level forcing is intentionally left off: LACT owns the
  # GPU here, and amdgpu's "auto" mode already ramps to max under load.
  programs.gamemode.enable = true;

  # gamemode's polkit rule only grants the cpu-governor helper to members of
  # the "gamemode" group, so the user must be in it — otherwise the governor
  # change silently fails (polkit denies).
  users.users.gvarph.extraGroups = ["gamemode"];

  environment.systemPackages = with pkgs; [
    gamescope
    gamescope-wsi # HDR won't work without this
    mangohud # FPS/temp/usage overlay; run with `mangohud %command%`
  ];
}
