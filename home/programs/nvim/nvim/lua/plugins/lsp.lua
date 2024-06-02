return {
    "neovim/nvim-lspconfig",
    config = function()
        local lspconfig = require("lspconfig")
        lspconfig.pyright.setup({})
        lspconfig.terraformls.setup({})
    end
}
