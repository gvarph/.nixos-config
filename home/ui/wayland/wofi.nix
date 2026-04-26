{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    libqalculate
    xclip # Required for the copy-to-clipboard command
  ];

  programs.rofi = {
    enable = true;
    font = "FiraCode Nerd Font";
    terminal = "ghostty";
    plugins = [
      pkgs.rofi-calc
    ];

    # This sets the default behavior when you launch rofi
    extraConfig = {
      modi = "combi";
      combi-modi = "calc,drun";
      # This ensures the calculator result is shown even if no app matches
      no-show-match = true;
      # Keeps the calculation at the top
      no-sort = true;

      # Calculator specific logic
      calc-command = "echo -n '{result}' | xclip -selection clipboard";
      calc-hint-result = ""; # Setting this to empty often forces it to show
    };

    # CRITICAL: This ensures the 'message' area (where math results live) is visible
    theme = let
      inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "mainbox" = {
        children = map mkLiteral ["inputbar" "message" "listview"];
      };
      "message" = {
        padding = mkLiteral "5px";
        border = mkLiteral "0px 0px 2px";
      };
    };
  };
}
