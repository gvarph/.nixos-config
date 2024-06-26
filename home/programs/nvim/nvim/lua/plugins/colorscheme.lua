return { -- add gruvbox
{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
        transparent_background = true,
    }

}, {
    "LazyVim/LazyVim",
    opts = {
        colorscheme = "catppuccin"
    }
}}
