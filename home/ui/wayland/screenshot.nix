{pkgs, ...}: let
  # screenshot [region|screen] [clipboard|file]
  #
  # Region mode freezes the screen with wayfreeze *before* slurp starts, so
  # hover/focus-only UI (tooltips, menus) is still there when selecting, and
  # grim then captures the frozen overlay. --hide-cursor keeps the cursor out
  # of the frozen image; this only works with hardware cursors (see
  # cursor.no_hardware_cursors in hyprland/lua/input.lua): a software
  # cursor is baked into every screencopy frame.
  screenshot = pkgs.writeShellApplication {
    name = "screenshot";
    runtimeInputs = with pkgs; [grim slurp wayfreeze wl-clipboard coreutils];
    text = ''
      mode=''${1:-region}
      dest=''${2:-clipboard}

      capture() {
        if [ "$dest" = file ]; then
          dir="$HOME/Pictures/Screenshots"
          mkdir -p "$dir"
          file="$dir/$(date +%Y%m%d_%H%M%S).png"
          grim "$@" "$file"
          wl-copy --type image/png < "$file"
        else
          grim "$@" - | wl-copy --type image/png
        fi
      }

      case "$mode" in
        screen)
          capture
          ;;
        region)
          ready=$(mktemp -u)
          wayfreeze --hide-cursor --after-freeze-cmd "touch '$ready'" &
          freezer=$!
          trap 'kill "$freezer" 2>/dev/null; rm -f "$ready"' EXIT
          until [ -e "$ready" ]; do
            kill -0 "$freezer" 2>/dev/null || exit 1
            sleep 0.01
          done
          # Esc in slurp cancels without a screenshot
          geometry=$(slurp) || exit 0
          capture -g "$geometry"
          ;;
        *)
          echo "usage: screenshot [region|screen] [clipboard|file]" >&2
          exit 1
          ;;
      esac
    '';
  };
in {
  home.packages = [screenshot];
}
