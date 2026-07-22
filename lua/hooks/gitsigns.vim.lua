-- lua_add {{{
-- TODO: check `on_attach` of `gitsigns` and check the way to `in_attach` or set keymap.set direct
-- }}}
-- lua_source {{{
require('gitsigns').setup {
	-- kyodou
	update_debounce     = 1000,
	auto_attach         = true,
	attach_to_untracked = false,
	preview_config      = {
		-- Options passed to nvim_open_win
		style = 'minimal',
		relative = 'cursor',
		row = 0,
		col = 1
	},
	-- signs
	signcolumn          = true, -- Toggle with `:Gitsigns toggle_signs`
	signs               = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' }
	},
	signs_staged        = {
		add          = { text = '┃' },
		change       = { text = '┃' },
		delete       = { text = '_' },
		topdelete    = { text = '‾' },
		changedelete = { text = '~' },
		untracked    = { text = '┆' }
	},
	signs_staged_enable = true,
	numhl               = true,     -- Toggle with `:Gitsigns toggle_numhl`
	linehl              = false,   -- Toggle with `:Gitsigns toggle_linehl`
	word_diff           = true, -- Toggle with `:Gitsigns toggle_word_diff`
	watch_gitdir        = {
		follow_files = true
	},
	-- blame
	current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
		delay = 1000,
		ignore_whitespace = false,
		virt_text_priority = 100,
		use_focus = true
	},
	current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
	blame_formatter = nil       -- Use default
}
-- }}}
