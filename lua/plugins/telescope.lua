return {
	{ -- Fuzzy Finder (files, lsp, etc)
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		branch = "0.1.x",
		dependencies = {
			{ "nvim-lua/plenary.nvim" },
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			local file_ignore_patterns = {
				"node_modules/*",
				"^.git/*",
				"vendor/*",
				"zz_generated*",
				"openapi_generated*",
			}

			local telescope_setup = require("telescope").setup({
				defaults = {
					file_ignore_patterns = file_ignore_patterns,
					preview = {
						treesitter = true,
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			require("telescope").setup({
				defaults = telescope_setup,
			})

			local current_ignore_patterns = file_ignore_patterns

			local function toggle_ignore_patterns()
				if #current_ignore_patterns == 0 then
					current_ignore_patterns = file_ignore_patterns
				else
					current_ignore_patterns = {}
				end

				require("telescope").setup({
					defaults = {
						file_ignore_patterns = current_ignore_patterns,
					},
				})
				vim.notify(
					"Telescope ignore patterns updated to: " .. vim.inspect(current_ignore_patterns),
					vim.log.levels.INFO
				)
			end

			vim.keymap.set(
				"n",
				"<leader>ti",
				toggle_ignore_patterns,
				{ noremap = true, silent = true, desc = "[T]oggle [I]gnore patterns" }
			)

			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
			pcall(require("telescope").load_extension, "projects")

			pcall(require("telescope").load_extension, "big_snippets")
			vim.keymap.set("n", "<leader>ss", ":Telescope big_snippets<CR>", { desc = "[S]earch [S]nippets" })

			vim.keymap.set("n", "<leader>sp", ":Telescope projects<CR>", { desc = "[S]earch [P]rojects" })

			vim.keymap.set("n", "<leader>sc", ":Telescope git_commits<CR>", { desc = "[S]earch [C]ommits" })
			vim.keymap.set("n", "<leader>sb", ":Telescope git_branches<CR>", { desc = "[S]earch [B]ranches" })
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "gd", builtin.lsp_definitions, { desc = "[G]oto [D]efinition" })
			vim.keymap.set("n", "gr", builtin.lsp_references, { desc = "[G]oto [R]eferences" })
			vim.keymap.set("n", "gi", builtin.lsp_implementations, { desc = "[G]oto [I]mplementations" })
			vim.keymap.set("n", "<leader>ws", builtin.lsp_dynamic_workspace_symbols, { desc = "[W]orkspace [S]ymbols" })
			vim.keymap.set("n", "<leader>ds", builtin.lsp_document_symbols, { desc = "[D]ocument [S]ymbols" })

			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>gf", builtin.git_files, { desc = "Search [G]it [F]iles" })
			vim.keymap.set("n", "<leader>gs", builtin.git_stash, { desc = "Search [G]it [S]tash" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sn", ":Telescope notify<CR>", { desc = "[S]earch [N]otify" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })

			vim.keymap.set("n", "<leader>/", function()
				builtin.current_buffer_fuzzy_find({})
			end, { desc = "[/] Fuzzily search in current buffer" })
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })
		end,
	},
}
