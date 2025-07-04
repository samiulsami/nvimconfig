return {
	"mikavilpas/yazi.nvim",
	event = "VeryLazy",
	keys = {
		{
			"<leader>p",
			mode = { "n", "v" },
			"<cmd>Yazi<cr>",
			desc = "Open yazi at the current file",
		},
		{
			"<leader>cw",
			"<cmd>Yazi cwd<cr>",
			desc = "Open the file manager in nvim's working directory",
		},
	},
	---@module 'yazi'
	---@type YaziConfig | {}
	opts = {
		open_for_directories = true,
		keymaps = {
			show_help = "<f1>",
			change_working_directory = "`",
			grep_in_directory = "<c-s>",
			replace_in_directory = "<c-r>",
			cycle_open_buffers = "O",
		},
		integrations = {
			grep_in_directory = function(directory)
				require("snacks").picker.grep({
					dirs = { directory },
					hidden = true,
					ignored = true,
					live = false,
					need_search = false,
				})
				vim.api.nvim_feedkeys("i", "n", false)
			end,
		},
	},
}
