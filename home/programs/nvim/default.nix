{
  config,
  pkgs,
  ...
}: let
  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in {
  home.file.".config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };

  # Treesiter is configured as a locally developed plugin in lazy.nvim
  #   so we have to hardcode a symlink to the treesitter parsers
  #   to which we can refer to in the lazy.nvim config
  home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
    recursive = true;
    source = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
  };

  home.file.".config/nvim/lua/gvarph/init.lua".text = ''
    require("gvarph.set")
    require("gvarph.keymaps")
    vim.opt.runtimepath:append("${treesitter-parsers}")
  '';

  programs.neovim = {
    enable = true;

    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    defaultEditor = true;

    withNodeJs = true;
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars
    ];

    extraPackages = with pkgs; [
      git # Needed to install lazy.nvim
      nil
      lua-language-server
      zig # C compiler
      ripgrep
      fd
      fzf
      tree-sitter
      taplo
      # Python stuff
      # pyright
      basedpyright
      poetry
      ruff
      python312Packages.debugpy
      rust-analyzer
      yaml-language-server
      terraform-ls

      stylua

      # Typst
      typst-lsp
      typstyle
    ];
  };
}
