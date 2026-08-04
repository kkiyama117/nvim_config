-- lua_add {{{
-- Global Key mapping to call Ddu-ui-filer.
-- }}}
--
-- NOTE: ddu-ui-filer duplicates a directory's children after mutating
-- item-actions (`newFile`/`delete`/...).  See `sync_dir_after_item_action`
-- below for the workaround.

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

-- --------------------------------------------------------------------------
-- Workaround for ddu-ui-filer showing a directory's children twice after a
-- mutating item-action (`newFile`, `newDirectory`, `delete`, `trash`, `move`,
-- `rename`, `paste`, `link`, `copy`).
--
-- These kind-actions return `ActionFlags.RefreshItems` + `searchPath`, so the
-- ddu core re-expands the affected dir twice during the redraw: once via
-- `restoreTree` (re-applying `#expandedItems`) and once via the `searchPath`
-- walk.  ddu-ui-filer's `expandItem` override *appends* the children without
-- clearing the existing ones, so the second expand inserts them again and
-- the directory's contents appear duplicated -- until the folder is
-- collapsed and re-expanded manually.
--
-- We automate that manual fix: after the action, find the expanded dir whose
-- children may have been duplicated (same rule as ddu-kind-file's
-- `getTargetDirectory()`, applied to the post-action cursor item), move the
-- filer cursor onto it, toggle-collapse then toggle-expand (a single fresh
-- gather), then put the cursor back on the originally-targeted item.
-- `ddu#ui#do_action` is a synchronous denops request, so the steps are
-- properly ordered.
local function set_filer_cursor(lnum)
	pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
	-- Force the filer's cursor-pos bufvar to match, even if the visible cursor
	-- was already on `lnum` (in which case CursorMoved would not fire).
	vim.b.ddu_ui_filer_cursor_pos = vim.fn.getcurpos()
end

local function find_item_line(path)
	for i, it in ipairs(vim.b.ddu_ui_items or {}) do
		local a = it.action or {}
		if a.path == path then
			return i
		end
	end
	return nil
end

local function sync_dir_after_item_action()
	local item = vim.fn['ddu#ui#get_item']() or {}
	local action = item.action or {}
	local path = action.path or item.word or ''
	if path == '' then
		return
	end

	-- The expanded directory whose children may be duplicated: same logic as
	-- ddu-kind-file's `getTargetDirectory()` applied to the post-action item.
	--   newFile/newDirectory(=file/just-created dir) -> dirname(path)
	--   delete (=cursor lands on the dir, expanded)        -> path
	local dir
	if item.isTree and item.__expanded then
		dir = path
	else
		dir = vim.fn.fnamemodify(path, ':h')
	end
	if dir == '' or dir == '.' then
		return
	end

	-- Only a dir that is currently expanded in the filer can have duplicated
	-- children; if it is not visible/expanded there is nothing to fix.
	local parent_idx
	for i, it in ipairs(vim.b.ddu_ui_items or {}) do
		local a = it.action or {}
		if it.isTree and it.__expanded and a.path == dir then
			parent_idx = i
			break
		end
	end
	if not parent_idx then
		return
	end

	-- Collapse then re-expand: the toggle reads the item under the filer cursor.
	set_filer_cursor(parent_idx)
	vim.fn['ddu#ui#do_action']('expandItem',
		{ mode = 'toggle', isGrouped = true, isInTree = false })
	set_filer_cursor(parent_idx)
	vim.fn['ddu#ui#do_action']('expandItem',
		{ mode = 'toggle', isGrouped = true, isInTree = false })

	-- Put the cursor back on the originally-targeted item if it is still visible
	-- (e.g. the newly created file).  For `delete`/`trash` it is gone, so the
	-- cursor stays on the re-synced directory.
	local restored = find_item_line(path)
	if restored then
		set_filer_cursor(restored)
	end
end

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

-- Re-sync the expanded directory under the cursor after a mutating
-- item-action (`newFile`/`delete`/...).  ddu-ui-filer's built-in `redraw`
-- does NOT fix the duplicated-children bug (it re-runs `restoreTree`, which
-- appends the children again).  `R` collapses + re-expands the affected dir
-- (a single fresh gather), which is the only thing that cleans it.
vim.keymap.set('n', 'R', sync_dir_after_item_action, opts)

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

