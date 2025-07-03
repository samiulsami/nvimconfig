---@class ffTt_highlights.opts
---@field public f string | nil
---@field public F string | nil
---@field public t string | nil
---@field public T string | nil
---@field public esc string | nil
---@field public next string | nil
---@field public prev string | nil
---@field public dot string | nil
---@field public backdrop_strategy "minimal" | "full" | "none" | nil
---@field public match_highlight_strategy "minimal" | "full" | "none" | nil -- WIP
---@field public disabled_filetypes table<string> | nil
---@field public disabled_buftypes table<string> | nil
---@field public modes table<string> | nil allowed = {"n", "v", "o"}
---@field public smart_motions boolean | nil

---@class last_state
---@field motion string
---@field char string

---@class ffTt_highlights
---@field private pending_motions integer
---@field private in_motion boolean
---@field private charmap table<string, string>
---@field private disabled_file_or_buftype fun(self, opts: ffTt_highlights.opts): boolean
---@field private rev_map table<string, string>
---@field private fTfT_ns number
---@field private validate_opts fun(self, opts: ffTt_highlights.opts): nil
---@field private redraw fun(): nil
---@field private backdrop_highlight string
---@field private match_highlight string
---@field private candidate_pending_char string
---@field private get_char fun(self, opts: ffTt_highlights.opts): string | nil
---@field private setup_highlights fun(self): nil
---@field private set_backdrop_highlight fun(self, bufnr: number, line: string, char_boundary?: string, row: number, from: number, to: number): nil
---@field private set_match_highlight fun(self, bufnr: number, row: number, line: string,  from: number, to: number, char: string): nil
---@field private setup_highlight_reset_trigger fun(self, modes: table<string>, opts: ffTt_highlights.opts): nil
---@field private last_state last_state | nil
---@field private replay_last fun(self, opts: ffTt_highlights.opts, rev: boolean): nil
---@field public clear_fFtT_hl fun(self): nil clears backdrop and highlights
---@field public setup fun(self, opts?: ffTt_highlights.opts): nil
local fFtT_hl = {
	pending_motions = 0,
	in_motion = false,
	charmap = {
		["<space>"] = " ",
		["<lt>"] = "<",
	},
	rev_map = {},
	backdrop_highlight = "fFtTBackDropHighlight",
	match_highlight = "fFtTMatchHighlight",
	candidate_pending_char = "",
}

---@type ffTt_highlights.opts
local default_opts = {
	f = "f",
	F = "F",
	t = "t",
	T = "T",
	next = ";", --- buggy
	prev = ",",
	dot = ".",
	esc = "<Esc>",
	disabled_filetypes = {},
	disabled_buftypes = {},
	backdrop_strategy = "minimal",
	modes = { "n", "v", "o" },
	smart_motions = false, --- doesn't work with macros
}

---@param opts? ffTt_highlights.opts
function fFtT_hl:setup(opts)
	opts = opts or {}
	opts = vim.tbl_deep_extend("force", default_opts, opts)
	self:validate_opts(opts)

	self.rev_map[opts.f] = "f"
	self.rev_map[opts.F] = "F"
	self.rev_map[opts.t] = "t"
	self.rev_map[opts.T] = "T"
	self.rev_map[opts.next] = ";"
	self.rev_map[opts.prev] = ","
	self.rev_map[opts.dot] = "."

	self:setup_highlights()
	self:setup_highlight_reset_trigger(opts.modes, opts)
	for _, motion in ipairs({ opts.f, opts.F, opts.t, opts.T }) do
		self:map_fFtT_motions(motion, opts)
	end

	vim.keymap.set("n", opts.next, ";", { noremap = false })
	vim.keymap.set("n", opts.prev, ",", { noremap = false })
	vim.keymap.set("n", opts.dot, ".", { noremap = false })

	local fFtT_hl_clear_group = vim.api.nvim_create_augroup("fFtTHLClearGroup", { clear = true })
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = fFtT_hl_clear_group,
		callback = function()
			self.pending_motions = 0
			self.in_motion = false
			self:clear_fFtT_hl()
			self.redraw()
		end,
	})
end

---@param opts ffTt_highlights.opts
function fFtT_hl:validate_opts(opts)
	for _, m in ipairs(opts.modes) do
		if m ~= "n" and m ~= "v" and m ~= "o" then
			error("Invalid mode: '" .. m .. "' in ffTt_highlights.opts. Allowed: n, v, o")
		end
	end
end

function fFtT_hl:setup_highlights()
	self.fFtT_ns = vim.api.nvim_create_namespace("highlightFfTtMotion")
	local incsearch_highlight = vim.api.nvim_get_hl(0, { name = "IncSearch" })
	local comment_highlight = vim.api.nvim_get_hl(0, { name = "Comment" })
	vim.api.nvim_set_hl(0, self.match_highlight, { fg = incsearch_highlight.fg, bg = incsearch_highlight.bg })
	vim.api.nvim_set_hl(0, self.backdrop_highlight, { fg = comment_highlight.fg, bg = comment_highlight.bg })
end

---@param modes table<string>
---@param opts ffTt_highlights.opts
function fFtT_hl:setup_highlight_reset_trigger(modes, opts)
	vim.on_key(function(char)
		if self:disabled_file_or_buftype(opts) then
			return
		end
		char = vim.fn.keytrans(char)
		if char == opts.esc then
			self.pending_motions = 0
			self.in_motion = false
			self:clear_fFtT_hl()
			return
		end

		char = self.charmap[char:lower()] or char
		if self.pending_motions > 0 then
			self.pending_motions = self.pending_motions - 1
			self.candidate_pending_char = char
			return
		end

		local mode = vim.api.nvim_get_mode().mode
		if not vim.tbl_contains(modes, mode) then
			return
		end

		if char == opts.dot or char == opts.prev or char == opts.next then
			if char == opts.dot then
				self.pending_motions = 3
			end
			self:replay_last(opts, char == opts.prev)
			return
		end

		self.pending_motions = 0
		self.in_motion = false
		self:clear_fFtT_hl()
	end, vim.api.nvim_create_namespace("highlightFfTtMotionKeyWatcher"))
end

---@param motion string
---@param opts ffTt_highlights.opts
function fFtT_hl:map_fFtT_motions(motion, opts)
	vim.keymap.set(opts.modes, motion, function()
		if self:disabled_file_or_buftype(opts) then
			return
		end
		if opts.smart_motions and self.in_motion then
			if motion == opts.f or motion == opts.t then
				return ";"
			else
				return ","
			end
		end
		if vim.fn.reg_executing() ~= "" then
			return self.rev_map[motion]
		end

		self:clear_fFtT_hl()
		self.redraw()

		self.pending_motions = 1
		local bufnr = vim.api.nvim_get_current_buf()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		if not line then
			return
		end

		local from, to
		if motion == opts.f or motion == opts.t then
			from, to = col + 1, #line - 1
		elseif motion == opts.F or motion == opts.T then
			from, to = 0, col - 1
		end

		if opts.backdrop_strategy ~= "none" then
			self:set_backdrop_highlight(bufnr, line, nil, row, from, to)
			self.redraw()
		end

		local char = self:get_char(opts)
		if not char then
			return
		end

		if opts.backdrop_strategy == "minimal" then
			self:clear_fFtT_hl()
			self:set_backdrop_highlight(bufnr, line, char, row, from, to)
		end

		local match_count = self:set_match_highlight(bufnr, row, line, from, to, char)
		if match_count <= 1 then
			self:clear_fFtT_hl()
		end

		self.redraw()

		self.pending_motions = self.pending_motions + 2
		self.last_state = {
			motion = motion,
			char = char,
		}
		self.in_motion = true
		return self.rev_map[motion] .. char
	end, { expr = true, noremap = true })
end

---@param opts ffTt_highlights.opts
---@param rev boolean
function fFtT_hl:replay_last(opts, rev)
	if vim.fn.reg_executing() ~= "" then
		return
	end
	self:clear_fFtT_hl()
	self.redraw()

	local last_state = self.last_state
	if not last_state then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if not line then
		return
	end

	local motion = last_state.motion
	if rev then
		if motion == opts.f then
			motion = opts.F
		elseif motion == opts.F then
			motion = opts.f
		elseif motion == opts.t then
			motion = opts.T
		elseif motion == opts.T then
			motion = opts.t
		end
	end

	local from, to
	if motion == opts.f or motion == opts.t then
		from, to = col + 1, #line - 1
	elseif motion == opts.F or motion == opts.T then
		from, to = 0, col - 1
	end

	if opts.backdrop_strategy ~= "none" then
		self:set_backdrop_highlight(
			bufnr,
			line,
			opts.backdrop_strategy == "minimal" and last_state.char or nil,
			row,
			from,
			to
		)
		self.redraw()
	end

	local match_count = self:set_match_highlight(bufnr, row, line, from, to, last_state.char)
	if match_count <= 1 then
		self:clear_fFtT_hl()
	end
	self.redraw()
	self.in_motion = true
end

---@param bufnr integer
---@param line string
---@param char_boundary? string
---@param row integer
---@param from integer
---@param to integer
function fFtT_hl:set_backdrop_highlight(bufnr, line, char_boundary, row, from, to)
	local left, right = from, to
	if left > right then
		left, right = right, left
	end

	if char_boundary then
		local left_boundary, right_boundary = -1, right
		for i = left, right do
			if line:sub(i + 1, i + 1) == char_boundary then
				if left_boundary == -1 then
					left_boundary = i
				end
				right_boundary = i
			end
		end
		left, right = left_boundary, right_boundary
		left = math.max(0, left - 1)
		right = math.min(#line - 1, right + 1)
	end

	for i = left, right do
		vim.api.nvim_buf_set_extmark(bufnr, self.fFtT_ns, row, i, {
			end_col = i + 1,
			hl_group = self.backdrop_highlight,
		})
	end
end

---@param bufnr integer
---@param row integer
---@param line string
---@param from integer
---@param to integer
---@param char string
---@return integer
function fFtT_hl:set_match_highlight(bufnr, row, line, from, to, char)
	local match_count = 0
	for i = from, to do
		if line:sub(i + 1, i + 1) == char then
			match_count = match_count + 1
			vim.api.nvim_buf_set_extmark(bufnr, self.fFtT_ns, row, i, {
				end_col = i + 1,
				hl_group = self.match_highlight,
			})
		end
	end
	return match_count
end

---@return string | nil
function fFtT_hl:get_char()
	local ok, key = pcall(vim.fn.getchar)
	if not ok then
		---HACK: This fixes an issue where the last char is not captured correctly when noice/nui loads.
		key = self.candidate_pending_char
	end

	local char
	if type(key) == "number" then
		char = vim.fn.keytrans(vim.fn.nr2char(key))
	elseif type(key) == "string" then
		char = vim.fn.keytrans(key)
	else
		return nil
	end

	return self.charmap[char:lower()] or char
end

---@param opts ffTt_highlights.opts
---@return boolean
function fFtT_hl:disabled_file_or_buftype(opts)
	if vim.tbl_contains(opts.disabled_filetypes, vim.bo.filetype) then
		return true
	end
	return vim.tbl_contains(opts.disabled_buftypes, vim.bo.buftype)
end

function fFtT_hl:clear_fFtT_hl()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, self.fFtT_ns, 0, -1)
	self.in_motion = false
end

fFtT_hl.redraw = function()
	vim.schedule(function()
		vim.cmd("redraw")
	end)
end

return fFtT_hl
