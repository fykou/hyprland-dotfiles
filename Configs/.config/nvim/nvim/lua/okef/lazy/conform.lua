return {
    'stevearc/conform.nvim',
    opts = {},
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "biome", "prettier", "prettierd", stop_after_first = true },
                typescript = { "biome", "prettier", "prettierd", stop_after_first = true },
                typescriptreact = { "biome", "prettier", "prettierd", stop_after_first = true },
            }
        })
    end
}

