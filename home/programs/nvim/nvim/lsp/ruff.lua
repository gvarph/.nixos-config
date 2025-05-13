return {
	cmd = { "ruff", "server" },
	filetypes = { "python" },
	root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
	on_init = function(client)
		-- Create the autocommand for this specific server
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("ruff_attach_config", { clear = true }),
			callback = function(args)
				local attached_client = vim.lsp.get_client_by_id(args.data.client_id)
				local bufnr = args.buf

				-- Only apply to the ruff client
				if attached_client and attached_client.name == "ruff" then
					-- Disable hover in favor of Pyright
					attached_client.server_capabilities.hoverProvider = false

					-- Create ruff commands
					vim.api.nvim_create_user_command("RuffAutoFix", function()
						vim.lsp.buf.execute_command({
							command = "ruff.applyAutofix",
							arguments = {
								{ uri = vim.uri_from_bufnr(bufnr) },
							},
						})
					end, { desc = "Ruff: Fix all auto-fixable problems" })

					vim.api.nvim_create_user_command("RuffOrganizeImports", function()
						vim.lsp.buf.execute_command({
							command = "ruff.applyOrganizeImports",
							arguments = {
								{ uri = vim.uri_from_bufnr(bufnr) },
							},
						})
					end, { desc = "Ruff: Format imports" })
				end
			end,
			desc = "LSP: Configure Ruff-specific settings",
		})

		return true -- Allow initialization to continue
	end,
}
