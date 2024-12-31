return {
	{
		"ggandor/leap.nvim",
		config = function()
			vim.keymap.set("n", "s", function()
				require("leap").leap({
					target_windows = require("leap.user").get_focusable_windows(),
				})
			end)
			vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
			vim.api.nvim_set_hl(0, "LeapLabel", { fg = "#ff0000", bold = true })
		end,
	},
}
