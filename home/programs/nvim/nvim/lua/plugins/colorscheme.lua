return { -- add gruvbox
	"catppuccin/nvim",
	name = "catppuccin",
	priority = 1000,
	opts = {
		transparent_background = true,
	},
	init = function()
		vim.cmd.colorscheme("catppuccin-mocha")
	end,
}
