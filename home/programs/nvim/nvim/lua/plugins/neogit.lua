-- -- init.lua
-- local neogit = require('neogit')
-- neogit.setup {}
return {
	"TimUntersberger/neogit",
	cmd = "Neogit",
	dependencies = { "nvim-lua/plenary.nvim", "sindrets/diffview.nvim" },
	opts = {
		integrations = {
			diffview = true,
		},
	},
	keys = {
		{
			"<leader>gs",
			function()
				require("neogit").open()
			end,
			desc = "[G]it [S]tatus",
		},
	},
}
