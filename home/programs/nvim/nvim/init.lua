local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.termguicolors = true
vim.opt.guicursor = ""

require("lazy").setup("plugins", {
	dev = {
		path = "~/.local/share/nvim/nix",
		fallback = false,
	},
})

require("gvarph")

local lsps = {
	"denols", -- JS, TS, JSX, TSX
	"helm_ls", -- Helm
	"lua_ls", -- Lua
	"nil_ls", -- Nix
	"postgres_lsp", -- Postgres
	"rust_analyzer", -- Rust
	"taplo", -- Toml
	"terraformls", -- Terraform
	"tinymist", -- Typst
	"yamlls", -- Yaml
	"basedpyright", -- Python
	"ruff", -- Python
}

for _, lsp in ipairs(lsps) do
	vim.lsp.enable(lsp)
end
