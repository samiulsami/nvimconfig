return {
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,

		config = function()
			vim.g.everforest_background = "hard"
			vim.g.everforest_better_performance = 1
			vim.cmd.colorscheme("everforest")

			local buffer_bg_color = "#1a1b1e"
			vim.api.nvim_set_hl(0, "Normal", { bg = buffer_bg_color })
			vim.api.nvim_set_hl(0, "NormalNC", { bg = buffer_bg_color })
			vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = buffer_bg_color })

			vim.api.nvim_set_hl(0, "LspReferenceText", { bold = true, underline = true })
			vim.api.nvim_set_hl(0, "LspReferenceRead", { bold = true, underline = true })
			vim.api.nvim_set_hl(0, "LspReferenceWrite", { bold = true, underline = true })

			vim.api.nvim_set_hl(0, "SymbolUsageRounding", { italic = true })
			vim.api.nvim_set_hl(0, "SymbolUsageContent", { fg = "#aaaaaa", italic = true })
			vim.api.nvim_set_hl(0, "SymbolUsageRef", { fg = "#ff6666", italic = true })
			vim.api.nvim_set_hl(0, "SymbolUsageImpl", { fg = "#6666ff", italic = true })
		end,
	},
}
