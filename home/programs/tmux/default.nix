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
      catppuccin
      vim-tmux-navigator
      yank
    ];

    extraConfig = ''
      set -ag terminal-overrides ',xterm-256color:RGB'

      set -g @catppuccin_flavour 'mocha'

      # Open panes in the current directory
      bind '"' split-window -v -c '#{pane_current_path}'
      bind % split-window -h -c '#{pane_current_path}'

      set -g @catppuccin_window_default_text "#W"
      set -g @catppuccin_window_text "#W"
      set -g @catppuccin_window_current_text "#W"
    '';
  };
}
