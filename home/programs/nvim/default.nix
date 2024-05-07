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

    extraLuaConfig = ''
    ${builtins.readFile ./nvim/init.lua}
    '';


    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars

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
	type = "lua";
	config = ''
	require'lspconfig'.pyright.setup{}
	'';
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

      # Python stuff
      nodePackages.pyright
      pyright
      poetry
      ruff
    ];
  };
}
