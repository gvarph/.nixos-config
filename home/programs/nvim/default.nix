{
  config,
  pkgs,
  ...
}: {
  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    defaultEditor = true;

    withPython3 = true;
    withNodeJs = true;

    extraLuaConfig = ''
      ${builtins.readFile ./nvim/init.lua}
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = builtins.readFile ./nvim/plugins/treesitter.lua;
      }

      nvim-lspconfig

      {
        plugin = catppuccin-nvim;
        config = "colorscheme catppuccin";
      }

      copilot-vim

      vim-tmux-navigator
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        config = builtins.readFile ./nvim/plugins/telescope.lua;
        type = "lua";
      }

      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./nvim/plugins/lsp.lua;
        type = "lua";
      }
      {
        plugin = neogit;
        config = builtins.readFile ./nvim/plugins/neogit.lua;
        type = "lua";
      }

      {
        plugin = diffview-nvim;
        config = builtins.readFile ./nvim/plugins/diffview.lua;
        type = "lua";
      }

      {
        plugin = gitsigns-nvim;
        config = builtins.readFile ./nvim/plugins/gitsigns.lua;
        type = "lua";
      }
    ];

    extraPackages = with pkgs; [
      git
      nil
      lua-language-server
      zig # C compiler
      ripgrep
      fd
      fzf
      lemonade # Clipboard manager
      tree-sitter
      # Python stuff
      nodePackages.pyright
      pyright
      poetry
      ruff

      terraform-ls
    ];
  };
}
