local picker_ignore_patterns = {
	"node_modules/*",
	"^.git/*",
	"vendor/*",
	"zz_generated*",
	"openapi_generated*",
}

return {
	{
		"folke/snacks.nvim",
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true, size = 1 * 1024 * 1024 },
			indent = { enabled = true, animate = { enabled = false } },
			input = { enabled = false },
			quickfile = { enabled = true },
			statuscolumn = { enabled = false },
			words = { enabled = true, debounce = 50 },
			notifier = { enabled = true, timeout = 1500, keys = { q = "close" } },
			explorer = { enabled = false },
			picker = { enabled = false },
		},
	},
}
