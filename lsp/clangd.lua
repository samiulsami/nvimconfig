return { -- Add clangd here
	cmd = { "clangd" },
	filetypes = { "c", "cpp", "objc", "objcpp" }, -- Supported filetypes
	root_dir = require("lspconfig.util").root_pattern("compile_commands.json", "Makefile", ".git"), -- Determine the root directory
	settings = {
		clangd = {
			-- Add any specific clangd settings here if needed
		},
	},
}
