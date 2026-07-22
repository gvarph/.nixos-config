# Gaming-related configuration (gamescope, gamemode, MangoHud).
# Currently imported only by the desktop host.
{pkgs, ...}: let
  # Steam launch-option helper: `gamescope-run <gamescope args> -- %command%`.
  # Fixes two things about running gamescope from Steam launch options:
  #  1. Steam LD_PRELOADs gameoverlayrenderer.so into everything it spawns,
  #     including gamescope itself; the overlay hooking gamescope's Vulkan
  #     present loop degrades frame pacing (lag after ~20 min). Strip it for
  #     gamescope, restore it for the game so the in-game overlay still works.
  #  2. Mesa's RADV builtin-shader cache has a flock self-deadlock when one
  #     process creates two Vulkan instances (hangs gamescope before its
  #     window appears; present in 26.1.5 and git main as of 2026-07).
  #     Disable the cache for gamescope only; the game keeps whatever the
  #     caller set (so `MESA_SHADER_CACHE_DISABLE=true gamescope-run ...`
  #     still propagates to games that need it themselves, like PoE).
  gamescope-run = pkgs.writeShellScriptBin "gamescope-run" ''
    args=() game=() seen=
    for a in "$@"; do
      if [ -n "$seen" ]; then game+=("$a")
      elif [ "$a" = "--" ]; then seen=1
      else args+=("$a"); fi
    done

    # Env to restore for the game: put back the caller's value, or unset the
    # var if the caller didn't have it (so the game never inherits the
    # gamescope-only overrides below). env(1) needs -u options before
    # VAR=VAL assignments, hence two arrays.
    unsets=() sets=()
    if [ -n "''${LD_PRELOAD+x}" ]; then
      sets+=("LD_PRELOAD=$LD_PRELOAD")
    else
      unsets+=(-u LD_PRELOAD)
    fi
    if [ -n "''${MESA_SHADER_CACHE_DISABLE+x}" ]; then
      sets+=("MESA_SHADER_CACHE_DISABLE=$MESA_SHADER_CACHE_DISABLE")
    else
      unsets+=(-u MESA_SHADER_CACHE_DISABLE)
    fi

    unset LD_PRELOAD
    export MESA_SHADER_CACHE_DISABLE=true

    if [ -n "$seen" ]; then
      exec gamescope "''${args[@]}" -- env "''${unsets[@]}" "''${sets[@]}" "''${game[@]}"
    else
      exec gamescope "''${args[@]}"
    fi
  '';
in {
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
    gamescope-run
    gamescope-wsi # HDR won't work without this
    mangohud # FPS/temp/usage overlay; run with `mangohud %command%`
  ];
}
