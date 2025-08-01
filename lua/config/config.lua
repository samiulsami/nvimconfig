vim.opt.updatetime = 50
vim.g.loaded_netrw = 0
vim.g.loaded_netrwPlugin = 0
vim.opt.cursorcolumn = true
vim.opt.cursorline = true

local cursorXYGRP = vim.api.nvim_create_augroup("CursorXYGRP", { clear = true })
vim.api.nvim_create_autocmd(
	{ "InsertLeave", "WinEnter" },
	{ pattern = "*", command = "set cursorline cursorcolumn", group = cursorXYGRP }
)
vim.api.nvim_create_autocmd(
	{ "InsertEnter", "WinLeave" },
	{ pattern = "*", command = "set nocursorline nocursorcolumn", group = cursorXYGRP }
)

vim.opt.isfname:append("@-@")
vim.opt.autoread = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.mouse = "a"
vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.opt.grepformat = "%f:%l:%m"
vim.o.sessionoptions = "buffers,curdir,folds,help,tabpages,globals,winsize,winpos,terminal"
vim.opt.cmdheight = 0

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("HighlightOnYank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})

vim.diagnostic.config({
	underline = { severity = vim.diagnostic.severity.ERROR },
	update_in_insert = false,
	virtual_text = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚 ",
			[vim.diagnostic.severity.WARN] = "󰀪 ",
			[vim.diagnostic.severity.INFO] = "󰋽 ",
			[vim.diagnostic.severity.HINT] = "󰌶 ",
		},
	},
})

vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)
