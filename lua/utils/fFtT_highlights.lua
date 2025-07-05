---@class fFTt_highlights.opts
---@field public f string | nil f character. default: "f"
---@field public F string | nil F character. default: "F"
---@field public t string | nil t character. default: "t"
---@field public T string | nil T character. default: "T"
---@field public esc string | nil escape character. default: "<Esc>"
---@field public next string | nil next character. default: ";"
---@field public prev string | nil previous character. default: ","
---@field public dot string | nil dot character. default: "."
---@field public case_sensitivity "default" | "smart" | "none" | nil case sensitivity. default: "default"
---@field public backdrop_strategy "minimal" | "full" | "none" | nil how often to show backdrop. default: "minimal"
---@field public bind_backdrop_by_matching_chars boolean | nil whether to bound backdrop by matching characters. default: true
---@field public highlight_entire_line boolean | nil whether to highlight entire line. default: false
---@field public extended_backdrop_borders integer | nil extend backdrop border by this many characters. default: "1"
---@field public disabled_filetypes table<string> | nil disable highlighting for these filetypes
---@field public disabled_buftypes table<string> | nil disable highlighting for these buftypes
---@field public max_line_length integer | nil maximum line length to highlight. default: 500
---@field public modes table<string> | nil (changing these may lead to undefined behavior) modes to enable highlighting. default: { "n", "v", "o" }
---@field public smart_motions boolean | nil whether to use f/F/t/T to go to next/previous characters. default: false

---@class last_state
---@field motion string
---@field char string

---@class ffTt_highlights
---@field private in_motion boolean
---@field private charmap table<string, string>
---@field private map_fFtT_motions fun(self, motion: string, opts: fFTt_highlights.opts): nil
---@field private map_next_prev_motions fun(self, motion: string, opts: fFTt_highlights.opts): nil
---@field private execute_smart_motion fun(self, motion: string, opts: fFTt_highlights.opts): nil
---@field private disabled_file_or_buftype fun(self, opts: fFTt_highlights.opts): boolean
---@field private fTfT_ns number
---@field private validate_opts fun(self, opts: fFTt_highlights.opts): nil
---@field private redraw fun(): nil
---@field private backdrop_highlight string
---@field private match_highlight string
---@field private candidate_pending_char string
---@field private get_char fun(self): string | nil
---@field private setup_highlights fun(self): nil
---@field private set_backdrop_highlight fun(self,opts: fFTt_highlights.opts, bufnr: number, line: string, char_boundary?: string, row: number, from: number, to: number): nil
---@field private set_match_highlight fun(self, opts: fFTt_highlights.opts, bufnr: number, row: number, line: string,  from: number, to: number, char: string): nil
---@field private setup_highlight_reset_trigger fun(self, modes: table<string>, opts: fFTt_highlights.opts): nil
---@field private update_highlighted_lines fun(self, start: integer, end: integer): nil
---@field private hl_line_start integer | nil
---@field private hl_line_end integer | nil
---@field private last_state last_state | nil
---@field private reapply_last_highlight fun(self, opts: fFTt_highlights.opts, rev: boolean): nil
---@field private move_cursor_to_char fun(self, opts: fFTt_highlights.opts, line: string, motion: string, char: string, row: number, col: number, reverse: boolean): integer | nil
---@field public clear_fFtT_hl fun(self): nil clears backdrop and highlights
---@field public setup fun(self, opts?: fFTt_highlights.opts): nil
---@field private setup_done boolean
local fFtT_hl = {
	in_motion = false,
	charmap = {
		["<space>"] = " ",
		["<lt>"] = "<",
	},
	backdrop_highlight = "fFtTBackDropHighlight",
	match_highlight = "fFtTMatchHighlight",
	candidate_pending_char = "",
	setup_done = false,
}

---@type fFTt_highlights.opts
local default_opts = {
	f = "f",
	F = "F",
	t = "t",
	T = "T",
	next = ";",
	prev = ",",
	dot = ".",
	esc = "<Esc>",
	smart_motions = false,
	case_sensitivity = "default",
	backdrop_strategy = "minimal",
	bind_backdrop_by_matching_chars = true,
	extended_backdrop_borders = 1,
	highlight_entire_line = false,
	max_line_length = 500,
	disabled_filetypes = {},
	disabled_buftypes = {},
	modes = { "n", "v", "o" },
}

---@param opts? fFTt_highlights.opts
function fFtT_hl:setup(opts)
	if self.setup_done then
		return
	end
	opts = opts or {}
	opts = vim.tbl_deep_extend("force", default_opts, opts)
	self:validate_opts(opts)

	self.setup_done = true

	self:setup_highlights()
	self:setup_highlight_reset_trigger(opts.modes, opts)
	for _, motion in ipairs({ opts.f, opts.F, opts.t, opts.T }) do
		self:map_fFtT_motions(motion, opts)
	end
	for _, motion in ipairs({ opts.next, opts.prev }) do
		self:map_next_prev_motions(motion, opts)
	end

	local fFtT_hl_clear_group = vim.api.nvim_create_augroup("fFtTHLClearGroup", { clear = true })
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = fFtT_hl_clear_group,
		callback = function()
			self.in_motion = false
			self:clear_fFtT_hl()
			self.redraw()
		end,
	})
end

---@param opts fFTt_highlights.opts
function fFtT_hl:validate_opts(opts)
	if opts.extended_backdrop_borders and opts.extended_backdrop_borders < 0 then
		error("extended_backdrop_borders must be >= 0")
	end
	for _, m in ipairs(opts.modes) do
		if m ~= "n" and m ~= "v" and m ~= "o" then
			error("Invalid mode: '" .. m .. "' in opts. Allowed: n, v, o")
		end
	end
end

---@param opts fFTt_highlights.opts
---@param line string
---@param motion string
---@param char string
---@param row integer
---@param col integer
---@param reverse boolean
---@return integer | nil
function fFtT_hl:move_cursor_to_char(opts, line, motion, char, row, col, reverse)
	local match_pos = nil
	local from, to = col + 1, #line - 1
	if reverse then
		from, to = 0, col - 1
	end

	if motion == opts.t or motion == opts.T then
		if reverse then
			to = to - 1
		else
			from = from + 1
		end
	end

	if from > to then
		from, to = to, from
	end

	if reverse then
		-- AaaAA
		for i = to, from, -1 do
			if self:char_matches(opts, line:sub(i + 1, i + 1), char) then
				match_pos = i
				break
			end
		end
	else
		for i = from, to do
			if self:char_matches(opts, line:sub(i + 1, i + 1), char) then
				match_pos = i
				break
			end
		end
	end

	if match_pos and (motion == opts.T or motion == opts.t) then
		if reverse then
			match_pos = match_pos + 1
		else
			match_pos = match_pos - 1
		end
	end

	if match_pos and match_pos >= 0 and match_pos < #line then
		vim.api.nvim_win_set_cursor(0, { row + 1, match_pos })
		return match_pos
	end

	return nil
end

function fFtT_hl:setup_highlights()
	self.fFtT_ns = vim.api.nvim_create_namespace("highlightFfTtMotion")
	local incsearch_highlight = vim.api.nvim_get_hl(0, { name = "IncSearch" })
	local comment_highlight = vim.api.nvim_get_hl(0, { name = "Comment" })
	vim.api.nvim_set_hl(0, self.match_highlight, { fg = incsearch_highlight.fg, bg = incsearch_highlight.bg })
	vim.api.nvim_set_hl(0, self.backdrop_highlight, { fg = comment_highlight.fg, bg = comment_highlight.bg })
end

---@param modes table<string>
---@param opts fFTt_highlights.opts
function fFtT_hl:setup_highlight_reset_trigger(modes, opts)
	vim.on_key(function(_, typed_key)
		if self:disabled_file_or_buftype(opts) then
			return
		end

		typed_key = vim.fn.keytrans(typed_key)
		if typed_key == opts.esc then
			self.in_motion = false
			self.last_state = nil
			self:clear_fFtT_hl()
			return
		end

		if self.in_motion and vim.tbl_contains({ opts.f, opts.F, opts.t, opts.T, opts.next, opts.prev }, typed_key) then
			return
		end

		self.candidate_pending_char = typed_key

		local mode = vim.api.nvim_get_mode().mode
		if not vim.tbl_contains(modes, mode) then
			return
		end

		self.in_motion = false
		self:clear_fFtT_hl()
	end, vim.api.nvim_create_namespace("highlightFfTtMotionKeyWatcher"))
end

---@param motion string
---@param opts fFTt_highlights.opts
function fFtT_hl:map_fFtT_motions(motion, opts)
	vim.keymap.set(opts.modes, motion, function()
		if self:disabled_file_or_buftype(opts) then
			return
		end

		if opts.smart_motions and self.in_motion and self.last_state then
			return self:execute_smart_motion(motion, opts)
		end

		self:clear_fFtT_hl()
		self.redraw()

		local bufnr = vim.api.nvim_get_current_buf()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		if not line or #line > opts.max_line_length then
			return
		end

		local from, to, reverse
		reverse = false
		if motion == opts.f or motion == opts.t then
			from, to = col + 1, #line - 1
		elseif motion == opts.F or motion == opts.T then
			from, to = 0, col - 1
			reverse = true
		end

		if opts.backdrop_strategy ~= "none" and vim.fn.reg_executing() == "" then
			self:set_backdrop_highlight(opts, bufnr, line, nil, row, from, to)
			self.redraw()
		end

		local char
		if vim.fn.reg_executing() ~= "" then
			char = self.last_state and self.last_state.char or nil
		else
			char = self:get_char()
		end
		if not char or char == opts.esc then
			return
		end

		if motion == opts.T then
			to = to - 1
		elseif motion == opts.t then
			from = from + 1
		end

		if vim.fn.reg_executing() == "" then
			self:clear_fFtT_hl()
			self:set_backdrop_highlight(
				opts,
				bufnr,
				line,
				opts.backdrop_strategy == "minimal" and char or nil,
				row,
				from,
				to
			)

			local match_count = self:set_match_highlight(opts, bufnr, row, line, from, to, char)
			if match_count <= 1 then
				self:clear_fFtT_hl()
			end

			self.redraw()
		end

		self.last_state = {
			motion = motion,
			char = char,
		}
		self.in_motion = true
		self:move_cursor_to_char(opts, line, motion, char, row, col, reverse)
	end, { expr = false, noremap = true })
end

---@param opts fFTt_highlights.opts
---@param motion string
function fFtT_hl:execute_smart_motion(motion, opts)
	local bufnr = vim.api.nvim_get_current_buf()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if not line or #line > opts.max_line_length then
		return
	end

	local reverse
	if motion == opts.f or motion == opts.t then
		reverse = false
	elseif motion == opts.F or motion == opts.T then
		reverse = true
	end

	if vim.fn.reg_executing() == "" then
		self:reapply_last_highlight(opts, reverse)
	end
	self:move_cursor_to_char(opts, line, motion, self.last_state.char, row, col, reverse)
	self.last_state = {
		char = self.last_state.char,
		motion = motion,
	}
	self.in_motion = true
end

function fFtT_hl:map_next_prev_motions(motion, opts)
	vim.keymap.set(opts.modes, motion, function()
		if not self.last_state or self:disabled_file_or_buftype(opts) then
			return
		end
		local bufnr = vim.api.nvim_get_current_buf()
		local row, col = unpack(vim.api.nvim_win_get_cursor(0))
		row = row - 1
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		if not line then
			return
		end

		local last_motion = self.last_state.motion
		local reverse = (last_motion == opts.F or last_motion == opts.T)
		if motion == opts.prev then
			reverse = not reverse
		end

		self:reapply_last_highlight(opts, reverse)
		self:move_cursor_to_char(opts, line, last_motion, self.last_state.char, row, col, reverse)
		self.in_motion = true
	end, { expr = false, noremap = true })
end

---@param opts fFTt_highlights.opts
---@param rev boolean
function fFtT_hl:reapply_last_highlight(opts, rev)
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

	local from, to
	if rev then
		from, to = 0, col - 1
	else
		from, to = col + 1, #line - 1
	end

	if last_state.motion == opts.t or last_state.motion == opts.T then
		if rev then
			to = to - 1
		else
			from = from + 1
		end
	end

	if opts.backdrop_strategy ~= "none" then
		self:set_backdrop_highlight(
			opts,
			bufnr,
			line,
			opts.backdrop_strategy == "minimal" and last_state.char or nil,
			row,
			from,
			to
		)
		self.redraw()
	end

	local match_count = self:set_match_highlight(opts, bufnr, row, line, from, to, last_state.char)
	if match_count <= 1 then
		self:clear_fFtT_hl()
	end
	self.redraw()
end

---@param opts fFTt_highlights.opts
---@param bufnr integer
---@param line string
---@param char_boundary? string
---@param row integer
---@param from integer
---@param to integer
function fFtT_hl:set_backdrop_highlight(opts, bufnr, line, char_boundary, row, from, to)
	local left, right = from, to
	-- if opts.highlight_entire_line then
	-- 	left, right = 0, #line - 1
	-- end
	if left > right then
		left, right = right, left
	end

	if opts.bind_backdrop_by_matching_chars and char_boundary then
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
	end

	if opts.extended_backdrop_borders then
		left = math.max(0, left - opts.extended_backdrop_borders)
		right = math.min(#line - 1, right + opts.extended_backdrop_borders)
	end

	self:update_highlighted_lines(row, row + 1)
	for i = left, right do
		vim.api.nvim_buf_set_extmark(bufnr, self.fFtT_ns, row, i, {
			end_col = i + 1,
			hl_group = self.backdrop_highlight,
		})
	end
end

---@param opts fFTt_highlights.opts
---@param bufnr integer
---@param row integer
---@param line string
---@param from integer
---@param to integer
---@param char string
---@return integer
function fFtT_hl:set_match_highlight(opts, bufnr, row, line, from, to, char)
	if opts.highlight_entire_line then
		from, to = 0, #line - 1
	end
	self:update_highlighted_lines(row, row + 1)
	local match_count = 0
	for i = from, to do
		if self:char_matches(opts, line:sub(i + 1, i + 1), char) then
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

---@param opts fFTt_highlights.opts
---@param string_char string
---@param typed_char string
---@return boolean
function fFtT_hl:char_matches(opts, string_char, typed_char)
	if opts.case_sensitivity == "default" then
		return string_char == typed_char
	end

	if opts.case_sensitivity == "smart" then
		if typed_char == typed_char:lower() then
			return typed_char:lower() == string_char:lower()
		end
		return string_char == typed_char
	end

	return string_char == typed_char
end

---@param opts fFTt_highlights.opts
---@return boolean
function fFtT_hl:disabled_file_or_buftype(opts)
	if vim.tbl_contains(opts.disabled_filetypes, vim.bo.filetype) then
		return true
	end
	return vim.tbl_contains(opts.disabled_buftypes, vim.bo.buftype)
end

function fFtT_hl:update_highlighted_lines(start, end_)
	if not self.hl_line_start then
		self.hl_line_start = start
	end
	if not self.hl_line_end then
		self.hl_line_end = end_
	end
	self.hl_line_start = math.min(self.hl_line_start, start)
	self.hl_line_end = math.max(self.hl_line_end, end_)
end

function fFtT_hl:clear_fFtT_hl()
	if not self.hl_line_start then
		self.hl_line_start = 0
	end
	if not self.hl_line_end then
		self.hl_line_end = -1
	end

	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, self.fFtT_ns, self.hl_line_start, self.hl_line_end)

	self.hl_line_start = nil
	self.hl_line_end = nil
end

fFtT_hl.redraw = function()
	vim.schedule(function()
		vim.cmd("redraw")
	end)
end

return fFtT_hl
