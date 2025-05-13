vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true

vim.g.have_nerd_font = true

vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`

vim.opt.clipboard = "unnamedplus"

vim.opt.breakindent = true

vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes"

vim.opt.timeoutlen = 300

vim.o.scrolloff = 10

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", extends = ">", precedes = "<", nbsp = "␣" }

-- live preview substitutions
vim.opt.inccommand = "split"

vim.opt.cursorline = true

-- Enable filetype detection, plugins, and indentation
vim.cmd("filetype plugin indent on")

-- Enable syntax highlighting
vim.cmd("syntax on")

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Tab width of 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- Enable inlay hints by default
vim.lsp.inlay_hint.enable(true, { 0 })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Auto reload after external changes
vim.o.autoread = true

vim.opt.mouse = "a"
