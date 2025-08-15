return {
	{
		"ramilito/kubectl.nvim",
		-- use a release tag to download pre-built binaries
		version = "2.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		dependencies = "saghen/blink.download",
		config = function()
			require("kubectl").setup({
				log_level = vim.log.levels.INFO,
				auto_refresh = {
					enabled = true,
					interval = 300, -- milliseconds
				},
				diff = {
					bin = "kubediff", -- or any other binary
				},
				kubectl_cmd = { cmd = "kubectl", env = {}, args = {}, persist_context_change = false },
				terminal_cmd = nil, -- Exec will launch in a terminal if set, i.e. "ghostty -e"
				namespace = "All",
				namespace_fallback = {}, -- If you have limited access you can list all the namespaces here
				headers = {
					enabled = true,
					hints = true,
					context = true,
					heartbeat = true,
					skew = {
						enabled = true,
						log_level = vim.log.levels.OFF,
					},
				},
				lineage = {
					enabled = true, -- This feature is in beta at the moment
				},
				logs = {
					prefix = true,
					timestamps = true,
					since = "2h",
				},
				alias = {
					apply_on_select_from_history = true,
					max_history = 5,
				},
				filter = {
					apply_on_select_from_history = true,
					max_history = 10,
				},
				filter_label = {
					max_history = 20,
				},
				float_size = {
					-- Almost fullscreen:
					-- width = 1.0,
					-- height = 0.95, -- Setting it to 1 will cause bottom to be cutoff by statuscolumn

					-- For more context aware size:
					width = 0.9,
					height = 0.8,

					-- Might need to tweak these to get it centered when float is smaller
					col = 10,
					row = 5,
				},
				statusline = {
					enabled = false,
				},
				obj_fresh = 5, -- highlight if creation newer than number (in minutes)
				api_resources_cache_ttl = 60 * 60 * 3, -- 3 hours in seconds
			})

			vim.keymap.set("n", "<leader>k", function()
				require("kubectl").toggle()
			end, { noremap = true, silent = true })
		end,
	},
}
