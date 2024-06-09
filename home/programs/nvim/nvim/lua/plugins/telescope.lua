return {
    "nvim-telescope/telescope.nvim",
    keys = { -- add a keymap to browse plugin files
    {
        "<leader>ff",
        "<cmd>Telescope find_files<cr>",
        desc = "[F]ind [F]iles"
    }, {
        "<leader>fg",
        "<cmd>Telescope live_grep<cr>",
        desc = "[F]ind [G]rep"
    }, {
        "<leader>fb",
        "<cmd>Telescope buffers<cr>",
        desc = "[F]ind [B]uffers"
    }, {
        "<leader>fh",
        "<cmd>Telescope help_tags<cr>",
        desc = "[F]ind [H]elp"
    }, {
        "<leader>fk",
        "<cmd>Telescope keymaps<cr>",
        desc = "[F]ind [K]eymaps"
    }, {
        "<leader>fd",
        "<cmd>Telescope lsp_document_diagnostics<cr>",
        desc = "[F]ind [D]iagnostics"
    }, {
        "<leader>f.",
        "<cmd>Telescope lsp_code_actions<cr>",
        desc = "[F]ind [.]Code [A]ctions"
    }},
    -- change some options
    opts = {
        extensions = {
            fzf = {
                fuzzy = true, -- false will only do exact matching
                override_generic_sorter = true, -- override the generic sorter
                override_file_sorter = true, -- override the file sorter
                case_mode = "smart_case" -- or "ignore_case" or "respect_case"
                -- the default case_mode is "smart_case"
            }
        }
    }
}

