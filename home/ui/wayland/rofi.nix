{
  pkgs,
  config,
  ...
}: let
  inherit (config.lib.formats.rasi) mkLiteral;

  # Clipboard picker with inline image thumbnails.
  # For every `cliphist` entry that is an image, decode it to a temp file and
  # hand rofi the `text\0icon\x1f/path` dmenu protocol so it renders a preview.
  # Text entries pass through untouched. Selection is decoded back to the
  # Wayland clipboard.
  clipboard-picker = pkgs.writeShellScriptBin "clipboard-picker" ''
    tmp="''${XDG_RUNTIME_DIR:-/tmp}/cliphist-thumbs"
    rm -rf "$tmp"
    mkdir -p "$tmp"

    pick=$(${pkgs.cliphist}/bin/cliphist list \
      | ${pkgs.gawk}/bin/gawk -v dir="$tmp" -v cli="${pkgs.cliphist}/bin/cliphist" '
          match($0, /^([0-9]+)\t\[\[ ?binary data [0-9.]+ ?[KMGT]?iB ([[:alpha:]]+) [0-9]+x[0-9]+/, m) {
            file = dir "/" m[1] "." m[2]
            system("printf %s " m[1] " | " cli " decode > " file)
            printf "%s%cicon%c%s\n", $0, 0, 31, file
            next
          }
          { print }
        ' \
      | ${pkgs.rofi}/bin/rofi -dmenu -i -p "Clipboard") || exit 0

    [ -z "$pick" ] && exit 0
    printf '%s' "$pick" | ${pkgs.cliphist}/bin/cliphist decode | ${pkgs.wl-clipboard}/bin/wl-copy
  '';
in {
  home.packages = with pkgs; [
    libqalculate # backs rofi-calc
    xclip # Required for the calc copy-to-clipboard command
    papirus-icon-theme # icon theme used by rofi's `show-icons`
    gawk # used by the clipboard picker
    clipboard-picker
  ];

  programs.rofi = {
    enable = true;
    font = "FiraCode Nerd Font 12";
    terminal = "ghostty";
    plugins = [
      pkgs.rofi-calc
    ];

    # This sets the default behavior when you launch rofi
    extraConfig = {
      modi = "combi";
      combi-modi = "calc,drun";

      # Icons / previews
      show-icons = true;
      icon-theme = "Papirus-Dark";
      drun-display-format = "{name}";

      # Nerd Font glyphs used as the prompt for each mode
      display-combi = " ";
      display-drun = " ";
      display-calc = " ";

      # This ensures the calculator result is shown even if no app matches
      no-show-match = true;
      # Keeps the calculation at the top
      no-sort = true;
      # Score matches by fuzzy relevance instead of default levenshtein, so a
      # strong name match (e.g. "Steam" for "steam") outranks history-boosted
      # entries (e.g. frequently-launched Steam games)
      sorting-method = "fzf";
      # Default also matches exec/categories/keywords, which is why e.g.
      # Discord (Keywords contain "chat") or Steam games (Categories/Exec
      # mention "steam") show up for queries that only describe them, not
      # name them. Restrict to the name fields users actually type.
      drun-match-fields = "name,generic";

      # Calculator specific logic
      calc-command = "echo -n '{result}' | xclip -selection clipboard";
      calc-hint-result = ""; # Setting this to empty often forces it to show
    };

    # Layout / shape / icons only. Colours come from the Catppuccin module
    # (catppuccin.autoEnable), which auto-imports the Mocha palette — so all
    # the @mauve / @surface0 / @teal / … variables below are Catppuccin's.
    theme = {
      # Rounded, translucent surface so Hyprland's blur shows through,
      # matching the look of your tiled windows.
      "window" = {
        # Anchor to the top so the search bar stays put as the list resizes
        # (a centered window re-centers on every keystroke).
        location = mkLiteral "north";
        anchor = mkLiteral "north";
        y-offset = mkLiteral "25%";
        width = mkLiteral "42%";
        border = mkLiteral "2px";
        border-color = mkLiteral "@mauve";
        border-radius = mkLiteral "16px";
        background-color = mkLiteral "#1e1e2ee6"; # @base at ~90% opacity
      };

      "mainbox" = {
        children = map mkLiteral ["inputbar" "message" "listview"];
        padding = mkLiteral "14px";
        spacing = mkLiteral "10px";
      };

      # Search box: rounded pill with a mauve prompt glyph.
      "inputbar" = {
        children = map mkLiteral ["prompt" "entry"];
        background-color = mkLiteral "@surface0";
        border = mkLiteral "2px";
        border-color = mkLiteral "@surface2";
        border-radius = mkLiteral "12px";
        padding = mkLiteral "12px 16px";
        spacing = mkLiteral "10px";
      };
      "prompt" = {
        text-color = mkLiteral "@mauve";
        vertical-align = mkLiteral "0.5";
      };
      "entry" = {
        placeholder = "Search…";
        placeholder-color = mkLiteral "@overlay0";
        vertical-align = mkLiteral "0.5";
      };

      # Calculator result / messages, set apart with a teal outline.
      "message" = {
        background-color = mkLiteral "@surface0";
        border = mkLiteral "2px";
        border-color = mkLiteral "@teal";
        border-radius = mkLiteral "12px";
        padding = mkLiteral "12px 16px";
      };
      "textbox" = {
        text-color = mkLiteral "@teal";
      };

      "listview" = {
        columns = 1;
        lines = 8;
        spacing = mkLiteral "4px";
        padding = mkLiteral "4px 0px 0px 0px";
        border = mkLiteral "0px";
        scrollbar = true;
        fixed-height = false;
        dynamic = true;
        cycle = true;
      };
      "scrollbar" = {
        handle-color = mkLiteral "@mauve";
        handle-width = mkLiteral "6px";
        border-radius = mkLiteral "12px";
      };

      # Rows: rounded and transparent (so the blur shows through), with a
      # mauve fill + pink outline when selected (echoes the waybar launcher).
      "element" = {
        border = mkLiteral "2px";
        border-color = mkLiteral "transparent";
        border-radius = mkLiteral "10px";
        padding = mkLiteral "8px 10px";
        spacing = mkLiteral "12px";
        cursor = mkLiteral "pointer";
      };
      "element normal.normal" = {background-color = mkLiteral "transparent";};
      "element normal.active" = {background-color = mkLiteral "transparent";};
      "element normal.urgent" = {background-color = mkLiteral "transparent";};
      "element alternate.normal" = {background-color = mkLiteral "transparent";};
      "element alternate.active" = {background-color = mkLiteral "transparent";};
      "element selected.normal" = {
        background-color = mkLiteral "@mauve";
        text-color = mkLiteral "@base";
        border-color = mkLiteral "@pink";
      };
      "element selected.active" = {
        background-color = mkLiteral "@mauve";
        text-color = mkLiteral "@base";
        border-color = mkLiteral "@pink";
      };

      # Bigger app icons.
      "element-icon" = {
        size = mkLiteral "30px";
        vertical-align = mkLiteral "0.5";
      };
      "element-text" = {
        highlight = mkLiteral "bold";
        vertical-align = mkLiteral "0.5";
      };
    };
  };
}
