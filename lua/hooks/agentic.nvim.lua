-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.

vim.keymap.set('n', '<Leader>a', function ()
	require('agentic').new_session()
end, { desc = 'agentic: new session' }
)
-- }}}

-- lua_source {{{
require("agentic").setup({
	provider = "pi-acp",
	--provider = "claude-agent-acp",
	acp_providers = {
		["pi-acp"] = {
			command = "/home/kiyama/.local/share/mise/installs/npm-pi-acp/latest/bin/pi-acp",
			initial_model = "ollama-cloud/deepseek-v4-flash",
			default_thought_level = "high"
		}
	},
	windows = {
		position = "right",
		width = "40%"
	},

	-- `keymaps` is deep-merged per key. Pass `{}` (empty list) to disable a
        -- binding (nil is skipped by deep-extend; false would crash multi_keymap_set).
	keymaps = {
		-- Keys for ALL buffers in the widget
		widget = {
			close                = "q",
			change_mode          = {},
			switch_provider      = {},
			switch_model         = {},
			change_thought_level = {}
		},

		-- Keys for the prompt/input buffer
		prompt = {
			submit            = {
				"<CR>"
			},
			paste_image       = {},
			accept_completion = {}
		},

		-- Chat buffer navigation (avoid clobbering Vim's `]]`/`[[`/`]t`/`[t`)
		chat = {
			next_heading   = {},
			prev_heading   = {},
			next_tool_call = {},
			prev_tool_call = {}
		},

		-- Diff preview navigation (avoid gitsigns' `]c`/`[c`)
		diff_preview = {
			next_hunk = {},
			prev_hunk = {}
		},

		-- Permission prompt cycling
		permission = {
			cycle_next = {},
			cycle_prev = {}
		}
	}
})
-- }}}
