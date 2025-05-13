return {
	"echasnovski/mini.nvim",
	version = "*",
	config = function()
		require("mini.surround").setup()
		require("mini.files").setup()
	end,
}
