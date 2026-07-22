-- lua_add {{{
-- Global Key mapping to call Ddu-ui-filer.
-- }}}

-- lua_source {{{
vim.api.nvim_create_autocmd({ 'TabEnter', 'WinEnter', 'CursorHold', 'FocusGained' }, {
	callback = function ()
		vim.fn['ddu#ui#do_action']('checkItems')
	end
})
-- }}}

-- ddu-filer {{{
lua << EOF
-- ==========================================================================
-- KEYMAPS (ddu-filer)
-- ==========================================================================
-- This file is loaded as an ftplugin for `ddu-filer` filetype (dpp parses
-- the `ddu-filer` marker as a per-filetype ftplugin).  It therefore runs
-- in the context of the actual ddu-filer buffer, so we can set <buffer>
-- mappings directly -- no FileType autocmd wrapper is needed (Shougo's
-- ddu-ui-filer.vim uses the same pattern with `nnoremap <buffer>`).

local function current_options()
	return vim.fn['ddu#custom#get_current'](vim.b.ddu_ui_name) or {}
end

local function toggle_hidden(name)
	local check = vim.tbl_isempty(
		(current_options().sourceOptions or {})[name] and (current_options().sourceOptions[name].matchers or {}) or {}
	)
	return check and { 'matcher_hidden' } or {}
end

local function toggle_ui_param(ui_name, param_name)
	local cur = current_options()
	local val = (cur.uiParams or {})[ui_name] and (cur.uiParams[ui_name] or {})[param_name]
	return val and false or true
end

local opts = { buffer = true, silent = true }

-- Actions
vim.keymap.set('n', 'a', function ()
	vim.fn['ddu#ui#do_action']('chooseAction')
end, opts)
vim.keymap.set('n', 'A', function ()
	vim.fn['ddu#ui#do_action']('inputAction')
end, opts)

-- Expand / collapse tree
vim.keymap.set('n', 'o', function ()
	vim.fn['ddu#ui#do_action'](
		'expandItem', { mode = 'toggle', isGrouped = true, isInTree = false }
	)
end, opts)
vim.keymap.set('n', 'O', function ()
	vim.fn['ddu#ui#do_action']('expandItem', { maxLevel = -1 })
end, opts)

-- Selection
vim.keymap.set('n', '<Space>', function ()
	vim.fn['ddu#ui#do_action']('toggleSelectItem')
end, opts)
vim.keymap.set('n', '*', function ()
	vim.fn['ddu#ui#do_action']('toggleAllItems')
end, opts)

-- Filter / quit
vim.keymap.set('n', 'i', function ()
	vim.fn['ddu#ui#do_action']('openFilterWindow')
end, opts)
vim.keymap.set('n', 'q', function ()
	vim.fn['ddu#ui#do_action']('quit')
end, opts)

-- File operations
vim.keymap.set('n', 'c', function ()
	vim.fn['ddu#ui#multi_actions']({
		{ 'itemAction', { name = 'copy' } },
		{ 'clearSelectAllItems' }
	})
end, opts)
vim.keymap.set('n', 'd', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'delete' })
end, opts)
vim.keymap.set('n', 'D', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'trash' })
end, opts)
vim.keymap.set('n', 'm', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'move' })
end, opts)
vim.keymap.set('n', 'r', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'rename' })
end, opts)
vim.keymap.set('n', 'x', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'executeSystem' })
end, opts)
vim.keymap.set('n', 'p', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'paste' })
end, opts)
vim.keymap.set('n', 'P', function ()
	vim.fn['ddu#ui#do_action']('togglePreview', { imageExts = { '.jpg', '.png' } })
end, opts)
vim.keymap.set('n', 'K', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'newDirectory' })
end, opts)
vim.keymap.set('n', 'N', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'newFile' })
end, opts)
vim.keymap.set('n', 'L', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'link' })
end, opts)
vim.keymap.set('n', 'u', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'undo' })
end, opts)

-- Narrow
vim.keymap.set('n', '~', function ()
	vim.fn['ddu#ui#do_action'](
		'itemAction', { name = 'narrow', params = { path = vim.fn.expand('~') } }
	)
end, opts)
vim.keymap.set('n', '=', function ()
	vim.fn['ddu#ui#do_action'](
		'itemAction', { name = 'narrow', params = { path = vim.fn.getcwd() } }
	)
end, opts)
vim.keymap.set('n', 'h', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'narrow', params = { path = '..' } })
end, opts)
vim.keymap.set('n', 'H', function ()
	vim.fn['ddu#start']({ sources = { { name = 'path_history' } } })
end, opts)
vim.keymap.set('n', 'I', function ()
	local path = vim.fn.input('cwd: ', vim.b.ddu_ui_filer_path, 'dir')
	path = vim.fn.fnamemodify(path, ':p')
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'narrow', params = { path = path } })
end, opts)

-- Options: fileFilter
vim.keymap.set('n', 'M', function ()
	local cur = current_options()
	local uiParams = cur.uiParams or {}
	local filerParams = uiParams.filer or {}
	local filter = vim.fn.input('fileFilter regexp: ', filerParams.fileFilter or '')
	vim.fn['ddu#ui#multi_actions']({
		{ 'updateOptions', { uiParams = { filer = { fileFilter = filter } } } },
		{ 'redraw', { method = 'refreshItems' } }
	})
end, opts)

-- Toggle hidden files
vim.keymap.set('n', '.', function ()
	local matchers = toggle_hidden('file')
	vim.fn['ddu#ui#multi_actions']({
		{ 'updateOptions', { sourceOptions = { file = { matchers = matchers } } } },
		{ 'redraw', { method = 'refreshItems' } }
	})
end, opts)

-- Toggle displayRoot
vim.keymap.set('n', '>', function ()
	local displayRoot = toggle_ui_param('filer', 'displayRoot')
	vim.fn['ddu#ui#multi_actions']({
		{ 'updateOptions', { uiParams = { filer = { displayRoot = displayRoot } } } },
		{ 'redraw' }
	})
end, opts)

-- Split vertical
vim.keymap.set('n', '<', function ()
	vim.fn['ddu#ui#multi_actions']({
		{ 'updateOptions', { uiParams = { filer = { split = 'vertical' } } } },
		{ 'redraw' }
	})
end, opts)

-- Redraw
vim.keymap.set('n', '<C-l>', function ()
	vim.fn['ddu#ui#do_action']('redraw')
end, opts)

-- Open / narrow (conditional on isTree)
vim.keymap.set('n', '<CR>', function ()
	local item = vim.fn['ddu#ui#get_item']() or {}
	local name = item.isTree and 'narrow' or 'open'
	vim.fn['ddu#ui#do_action']('itemAction', { name = name })
end, opts)
vim.keymap.set('n', 'l', function ()
	local item = vim.fn['ddu#ui#get_item']() or {}
	local name = item.isTree and 'narrow' or 'open'
	vim.fn['ddu#ui#do_action']('itemAction', { name = name })
end, opts)
vim.keymap.set('n', '<2-LeftMouse>', function ()
	local item = vim.fn['ddu#ui#get_item']() or {}
	local name = item.isTree and 'narrow' or 'open'
	vim.fn['ddu#ui#do_action']('itemAction', { name = name })
end, opts)

-- Grep
vim.keymap.set('n', 'gr', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'grep' })
end, opts)

-- Tab open
vim.keymap.set('n', 't', function ()
	vim.fn['ddu#ui#do_action']('itemAction', { name = 'tabopen', params = { command = 'tabedit' } })
end, opts)

-- Tree navigation
vim.keymap.set('n', 'T', function ()
	vim.fn['ddu#ui#do_action']('cursorTreeTop')
end, opts)
vim.keymap.set('n', 'B', function ()
	vim.fn['ddu#ui#do_action']('cursorTreeBottom')
end, opts)
EOF
-- }}}

