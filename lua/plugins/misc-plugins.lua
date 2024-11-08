return {
	{
		"folke/zen-mode.nvim",
		event = "VeryLazy",
	},
	{
		"Wansmer/symbol-usage.nvim",
		event = "BufReadPre", -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
		config = function()
			local SymbolKind = vim.lsp.protocol.SymbolKind
			require("symbol-usage").setup({
				kinds = {
					SymbolKind.Function,
					SymbolKind.Method,
					SymbolKind.Interface,
					SymbolKind.Class,
					SymbolKind.Struct,
					SymbolKind.Enum,
					SymbolKind.Constant,
					-- SymbolKind.Field,
					-- SymbolKind.Variable,
					-- SymbolKind.Object,
				},
			})
		end,
	},

	{ "AndrewRadev/splitjoin.vim" },

	{
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { desc = "Toggle UndoTree" })
		end,
	},

	{
		"anuvyklack/windows.nvim",
		dependencies = {
			"anuvyklack/middleclass",
		},
		config = function()
			require("windows").setup()

			vim.keymap.set("n", "<M-CR>", ":WindowsMaximize<CR>", { desc = "Toggle Windows" })
			vim.keymap.set("n", "<C-w>_", ":WindowsMaximizeVertically<CR>", { desc = "Vertically Maximize Windows" })
			vim.keymap.set(
				"n",
				"<c-w>|",
				":WindowsMaximizeHorizontally<CR>",
				{ desc = "Horizontally Maximize Windows" }
			)
			vim.keymap.set("n", "<c-w>=", ":WindowsEqualize<CR>", { desc = "Equalize Windows" })
		end,
	},
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		dependencies = { "hrsh7th/nvim-cmp" },
		config = function()
			require("nvim-autopairs").setup({})
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
		end,
	},

	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},

	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		config = function()
			require("ibl").setup()
		end,

		main = "ibl",
		---@module "ibl"
		---@type ibl.config
		opts = {},
	},
}
