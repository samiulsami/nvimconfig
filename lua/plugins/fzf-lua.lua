return {
	"ibhagwan/fzf-lua",
	-- optional for icon support
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local fzflua = require("fzf-lua")
		fzflua.setup({
			keymap = {
				fzf = {
					true,
					["ctrl-q"] = "select-all+accept",
				},
			},
		})

		--stylua: ignore start
		vim.keymap.set("n", "<leader>sf", function() fzflua.files({ cwd = vim.fn.getcwd() }) end)
		vim.keymap.set("n", "<leader>sg", function() fzflua.grep({ cwd = vim.fn.getcwd(), search = "" }) end)
		vim.keymap.set("n", "<leader>sp", function() fzflua.zoxide() end, {desc = "Zoxide Directories"})
		pcall(vim.api.nvim_del_keymap, "n", "grt")
		vim.keymap.set("n", "gr", function() fzflua.lsp_references() end, {desc = "LSP References"})
		vim.keymap.set("n", "gd", function() fzflua.lsp_definitions() end, {desc = "LSP Definitions"})
		vim.keymap.set("n", "gi", function() fzflua.lsp_implementations() end, {desc = "LSP Implementations"})
		vim.keymap.set("n", "gD", function() fzflua.lsp_declarations() end, {desc = "LSP Declarations"})
		-- stylua: ignore end
	end,
}
