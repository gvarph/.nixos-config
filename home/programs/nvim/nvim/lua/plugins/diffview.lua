return {
	"sindrets/diffview.nvim",
	config = function()
		require("diffview").setup({})

		-- Set <leader>dv to open Diffview
		vim.api.nvim_set_keymap("n", "<leader>dv", ":DiffviewOpen<CR>", { noremap = true, silent = true })
	end,
}
