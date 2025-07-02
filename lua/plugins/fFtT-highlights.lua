return {
	"samiulsami/fFtT-highlights.nvim",
	config = function()
		---@module "fFtT-highlights"
		---@type fFtT_highlights.opts
		require("fFtT-highlights"):setup({
			jumpable_chars = {
				show_instantly_jumpable = "always",
			},
		})
	end,
}
