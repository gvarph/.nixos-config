{
  config,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    sensibleOnTop = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    newSession = true;
    terminal = "tmux-256color";
    escapeTime = 0;
    # prefix = "C-b";
    historyLimit = 16384;

    aggressiveResize = true;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'

          set -g status-right-length 100
          set -g status-left ""

          # Window
          set -g @catppuccin_window_status_style "slanted"

          ## Window global/default configuration
          set -g @catppuccin_window_default_text " # {window_name}"
          set -g @catppuccin_window_number_position "left"

          set -g @catppuccin_window_text " # {window_name}"

          ## Window current configuration
          set -g @catppuccin_window_current_text "#{window_name}"
          set -g @catppuccin_window_current_fill "all"

          # Status modules config
          set -g @catppuccin_date_time_text " %y-%m-%d %H:%M"

        '';
      }
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      set -ag terminal-overrides ',xterm-256color:RGB'

      # Open panes in the current directory
      bind '"' split-window -v -c '#{pane_current_path}'
      bind % split-window -h -c '#{pane_current_path}'


          # Status
          set -gF  status-right "#{@catppuccin_status_directory}"
          set -agF status-right "#{@catppuccin_status_session}"
          set -agF status-right "#{@catppuccin_status_host}"
          set -agF status-right "#{E:@catppuccin_status_date_time}"
    '';
  };
}
