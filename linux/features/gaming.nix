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
  # Steam launch-option helper for PoE: `with-apt %command%` runs the game
  # with Awakened PoE Trade as a sidecar that lives and dies with it.
  #  - APT starts only once the actual game window exists (matching by the
  #    steam_app class — the Steam client window is also titled "Path of
  #    Exile", and APT started before the game has been seen to hold a
  #    stale keyboard map and inject wrong keys).
  #  - APT must not inherit Steam's library env: the ubuntu12 runtime's
  #    libnss3 is too old for its Electron and crashes it on startup.
  #  - When the game exits, APT is killed.
  with-apt = pkgs.writeShellScriptBin "with-apt" ''
    apt_job=
    # Skip the sidecar if an APT instance already runs (Electron enforces a
    # single instance anyway; don't adopt or kill one we didn't start).
    if ! pgrep -f 'awakened-poe-[t]rade.*app\.asar' >/dev/null 2>&1; then
      # setsid: own process group, so the whole Electron tree can be killed
      # as a group when the game exits.
      ${pkgs.util-linux}/bin/setsid bash -c '
        for _ in $(seq 1 180); do
          ${pkgs.xdotool}/bin/xdotool search --class steam_app_238960 >/dev/null 2>&1 && break
          sleep 1
        done
        exec env -u LD_LIBRARY_PATH -u LD_PRELOAD \
          ${pkgs.awakened-poe-trade}/bin/awakened-poe-trade
      ' &
      apt_job=$!
    fi
    "$@"
    status=$?
    if [ -n "$apt_job" ]; then
      # APT ignores SIGTERM, so give it a short grace then SIGKILL the group.
      kill -TERM -- "-$apt_job" 2>/dev/null
      for _ in 1 2 3; do
        kill -0 "$apt_job" 2>/dev/null || break
        sleep 1
      done
      kill -KILL -- "-$apt_job" 2>/dev/null
    fi
    exit $status
  '';
in {
  # Steam's gamescope micro-compositor session.
  # (Merges with the main programs.steam block in the host config.)
  programs.steam.gamescopeSession.enable = true;

  # sched-ext userspace scheduler (kernel has CONFIG_SCHED_CLASS_EXT via
  # CachyOS kernel). scx_lavd is the latency-aware scheduler CachyOS ships
  # for gaming (built for the Steam Deck) — better frame pacing under load.
  # Disable with `systemctl stop scx` if anything misbehaves.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

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
    with-apt
    mangohud # FPS/temp/usage overlay; run with `mangohud %command%`
  ];
}
