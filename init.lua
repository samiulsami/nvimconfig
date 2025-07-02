vim.g.mapleader = " "
vim.g.undotree_RelativeTimestamp = false
vim.g.maplocalleader = " "

require("config.lspconfig")
require("config.config")
require("config.formatting")
require("config.keybinds")
require("config.profiling")
require("config.lazy")
require("utils.unique_lines")

-- require("utils.fFtT_highlights"):setup({
-- 	multi_line = {
-- 		enable = true,
-- 		highlight_style = "minimal",
-- 	},
-- 	match_highlight = {
-- 		show_jump_numbers = true,
-- 	},
-- 	jumpable_chars = {
-- 		show_instantly_jumpable = "always",
-- 		show_multiline_jumpable = "on_key_press",
-- 	},
-- })
