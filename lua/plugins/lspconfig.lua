-- Modified lspconfig from kickstart.nvim
return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", config = true },
			{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
			{
				"kevinhwang91/nvim-ufo",
				dependencies = {
					"kevinhwang91/promise-async",
				},
				config = function()
					local ufo = require("ufo")
					vim.keymap.set("n", "zR", ufo.openAllFolds)
					vim.keymap.set("n", "zM", ufo.closeAllFolds)
					ufo.setup()
				end,
			},
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "b0o/schemastore.nvim" },
		},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			require("mason").setup()
			require("mason-tool-installer").setup({ ensure_installed = require("data.ensure_installed_mason") })

			vim.lsp.enable({ "gopls", "lua_ls", "helm_ls", "yamlls", "jsonls", "bashls" })
			vim.lsp.config("*", { capabilities = capabilities })

			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "LSP [R]e[n]ame" })
			vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "LSP [C]ode [A]ction" })
			vim.keymap.set(
				"n",
				"<leader>RL",
				":LspRestart",
				{ noremap = true, silent = true, desc = "[R]efresh [L]sp" }
			)

			vim.lsp.inlay_hint.enable(false)
			vim.keymap.set("n", "<leader>th", function()
				local hinstsEnabled = vim.lsp.inlay_hint.is_enabled()
				vim.lsp.inlay_hint.enable(not hinstsEnabled)
				if not hinstsEnabled then
					vim.notify("Inlay hints enabled")
				else
					vim.notify("Inlay hints disabled")
				end
			end, { desc = "[T]oggle Inlay [H]ints" })

			vim.api.nvim_set_hl(0, "LspReferenceText", { bold = true, underline = true })
			vim.api.nvim_set_hl(0, "LspReferenceRead", { bold = true, underline = true })
			vim.api.nvim_set_hl(0, "LspReferenceWrite", { bold = true, underline = true })
		end,
	},
}
