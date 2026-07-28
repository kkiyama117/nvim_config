-- ddu-ff {{{
lua << EOF
-- ==========================================================================
-- KEYMAPS
-- ==========================================================================

-- ddu-ui-ff keymaps. (Inside the `ddu-ff` buffer). See :h ddu-ui-ff for detail
local function item_is_directory() -- {{{
  local item = vim.fn['ddu#ui#get_item']() or {}
  local action = item.action or {}
  return action.isDirectory == true
end -- }}}
local function current_options() -- {{{
  return vim.fn['ddu#custom#get_current'](vim.b.ddu_ui_name) or {}
end -- }}}
-- KEYMAP {{{
-- itemAction: narrow (directory) / default (file)
    vim.keymap.set('n', '<CR>', function () -- {{{
      local params = item_is_directory() and { name = 'narrow' } or { name = 'default' }
      vim.fn['ddu#ui#do_action']('itemAction', params)
    end, {buffer = true, desc = "DDU: do_action"}) -- }}}
-- Mouse action
vim.keymap.set('n', '<2-LeftMouse>', function () -- {{{
  vim.fn['ddu#ui#do_action']('itemAction')
end, {buffer = true, desc = 'DDU: do_action'}) -- }}}
-- Toggle Select Item
vim.keymap.set({'n','x'}, '<Space>', function () -- {{{
  vim.fn['ddu#ui#do_action']('toggleSelectItem')
end, {buffer = true, silent=true, desc = 'DDU: toggle selection'}) -- }}}
-- Toggle All Items
vim.keymap.set('n', '*', function () -- {{{
  vim.fn['ddu#ui#do_action']('toggleAllItems')
end, {buffer = true, desc = "DDU: toggleAllItems"}) -- }}}
-- Filter
vim.keymap.set('n', 'i', function () -- {{{
  vim.fn['ddu#ui#do_action']('openFilterWindow')
end, {buffer = true, desc = 'DDU: openFilterWindow'}) -- }}}
-- refreshItems
vim.keymap.set('n', '<C-l>', function () -- {{{
  vim.fn['ddu#ui#do_action']('redraw', { method = 'refreshItems' })
end, {buffer=true,desc='DDU: refreshItems'}) -- }}}
-- previewPath
vim.keymap.set('n', 'p', function () -- {{{
  vim.fn['ddu#ui#do_action']('previewPath')
end, {buffer=true, desc="DDU: previewPath"}) -- }}}
-- toggle Preview
vim.keymap.set('n', 'P', function () -- {{{
  vim.fn['ddu#ui#do_action']('togglePreview')
end, {buffer=true, desc='DDU: togglePreview'}) -- }}}
-- quit
vim.keymap.set('n', 'qq', function () -- {{{
  vim.fn['ddu#ui#do_action']('quit')
end, {buffer=true, desc='DDU: quit'}) -- }}}

-- choose Action
vim.keymap.set('n', 'a', function () -- {{{
  vim.fn['ddu#ui#do_action']('chooseAction')
end, {buffer=true,desc='DDU: chooseAction'}) -- }}}
-- input Action
vim.keymap.set('n', 'A', function () -- {{{
  vim.fn['ddu#ui#do_action']('inputAction')
end, {buffer=true, desc='DDU: inputAction'}) -- }}}
-- choose Input
vim.keymap.set('n', 'I', function () -- {{{
  vim.fn['ddu#ui#do_action']('chooseInput')
end, {buffer=true,desc='DDU: chooseInput'}) -- }}}
-- expandItem?
vim.keymap.set('n', 'o', function () -- {{{
  vim.fn['ddu#ui#do_action']('expandItem', { mode = 'toggle' })
end, {buffer=true,desc='DDU: expandItem'}) -- }}}
-- collapseItem?
vim.keymap.set('n', 'O', function () -- {{{
  vim.fn['ddu#ui#do_action']('collapseItem')
end, {buffer=true, desc='DDU:collapseItem'}) -- }}}

-- delete / trash (filer ui -> trash, else delete)
-- Avoit mistapping now
-- vim.keymap.set('n', 'd', function()
--  local name = (vim.b.ddu_ui_name == 'filer') and 'trash' or 'delete'
--  vim.fn['ddu#ui#do_action']('itemAction', { name = name })
-- end, opts)

-- edit / narrow (directory -> narrow, else edit)
vim.keymap.set('n', 'e', function () -- {{{
  local name = item_is_directory() and 'narrow' or 'edit'
  vim.fn['ddu#ui#do_action']('itemAction', { name = name })
end, {buffer=true,desc='DDU: narrow_or_edit'}) -- }}}
-- itemAction with user-input params (eval'd as vim expr)
vim.keymap.set('n', 'E', function () -- {{{
  local params = vim.fn.eval(vim.fn.input('params: ', '{}'))
  vim.fn['ddu#ui#do_action']('itemAction', { params = params })
end, {buffer=true, desc="DDU: manual action"}) -- }}}
-- new file / new
vim.keymap.set('n', 'N', function () -- {{{
  local name = (vim.b.ddu_ui_name == 'file') and 'newFile' or 'new'
  vim.fn['ddu#ui#do_action']('itemAction', { name = name })
end, {buffer=true, desc='DDU: new'}) -- }}}
-- QuickFix
vim.keymap.set('n', 'r', function () -- {{{
  vim.fn['ddu#ui#do_action']('itemAction', { name = 'quickfix' })
end, {buffer=true, desc='DDU: QuickFix'}) -- }}}
-- yank
vim.keymap.set('n', 'yy', function () -- {{{
  vim.fn['ddu#ui#do_action']('itemAction', { name = 'yank' })
end, {buffer=true, desc='DDU: yank'}) -- }}}
-- grep
vim.keymap.set('n', 'gr', function () -- {{{
  vim.fn['ddu#ui#do_action']('itemAction', { name = 'grep' })
end, {buffer=true, desc='DDU: grep'}) -- }}}
-- narrow (same folder)
vim.keymap.set('n', 'n', function () -- {{{
  vim.fn['ddu#ui#do_action']('itemAction', { name = 'narrow' })
end, {buffer=true, desc='DDU: narrow'}) -- }}}
-- Kensaku.vim
vim.keymap.set('n', 'K', function () -- {{{
  vim.fn['ddu#ui#do_action']('kensaku')
end, {buffer=true, desc='DDU: vim-kensaku'} ) -- }}}
-- toggleAutoAction
vim.keymap.set('n', '<C-v>', function () -- {{{
  vim.fn['ddu#ui#do_action']('toggleAutoAction')
end, {buffer=true, desc='DDU: toggleAutoAction'}) -- }}}
-- Scroll preview down 
vim.keymap.set('n', '<C-p>', function () -- {{{
  vim.fn['ddu#ui#do_action']('previewExecute', { command = 'execute "normal! \\<C-y>"' })
end, {buffer=true, desc='DDU: preview scroll down'}) -- }}}
-- Scroll preview up
vim.keymap.set('n', '<C-n>', function () -- {{{
  vim.fn['ddu#ui#do_action']('previewExecute', { command = 'execute "normal! \\<C-e>"' })
end, {buffer=true, desc='DDU: preview scroll up'}) -- }}}

-- Switch options: matcher_files globs via cmdline#input
vim.keymap.set('n', 'u', function () -- {{{
  local globs = vim.split(
    vim.fn['cmdline#input']('Filter files: ', '', 'file'), ',',
    { plain = true, trimempty = true }
  )
  vim.fn['ddu#ui#multi_actions']({
    { 'updateOptions', { filterParams = { matcher_files = { globs = globs } } } },
    { 'redraw', { method = 'refreshItems' } }
  })
end, {buffer=true, desc='DDU: filter with globs'}) -- }}}

-- Switch sources: file
vim.keymap.set('n', 'ff', function () -- {{{
  vim.fn['ddu#ui#do_action']('updateOptions', { sources = { { name = 'file' } } })
  vim.fn['ddu#ui#do_action']('redraw', { method = 'refreshItems' })
end, {buffer=true, desc='Switch sources to "ff"'}) -- }}}

-- cursol Move
vim.keymap.set('n', '<C-n>', function () -- {{{
  vim.fn['ddu#ui#multi_actions']({ 'cursorNext', 'itemAction' }, 'files')
end, { silent = true, desc='DDU: next' }) -- }}}
vim.keymap.set('n', '<C-p>', function () -- {{{
  vim.fn['ddu#ui#multi_actions']({ 'cursorPrevious', 'itemAction' }, 'files')
end, { silent = true, desc='DDU: previous' }) -- }}}
vim.keymap.set('n', '<C-j>', function () -- {{{
  vim.fn['ddu#ui#do_action']('cursorNext')
end, {buffer=true,desc='DDU: j'}) -- }}}
vim.keymap.set('n', '<C-k>', function () -- {{{
  vim.fn['ddu#ui#do_action']('cursorPrevious')
end, {buffer=true, desc='DDU: previous'}) -- }}}

-- Widen ff window
    vim.keymap.set('n', '>', function () -- {{{
      vim.fn['ddu#ui#do_action']('updateOptions', { uiParams = { ff = { winWidth = 80 } } })
      vim.fn['ddu#ui#do_action']('redraw', { method = 'uiRedraw' })
    end, {buffer=true, desc="DDU: uiRedraw(Resize)"}) -- }}}
-- pathFilter (ff)
vim.keymap.set('n', 'M', function () -- {{{
  local cur = current_options()
  local uiParams = (cur.uiParams or {})
  local ffParams = (uiParams.ff or {})
  local pathFilter = vim.fn.input('pathFilter regexp: ', ffParams.pathFilter or '')
  vim.fn['ddu#ui#multi_actions']({
    { 'updateOptions', { uiParams = { ff = { pathFilter = pathFilter } } } },
    { 'redraw', { method = 'refreshItems' } }
  })
end, {buffer=true, desc="DDU: pathFilter"}) --}}}
-- rg globs
vim.keymap.set('n', 'U', function () -- {{{
  local cur = current_options()
  local sourceParams = (cur.sourceParams or {})
  local rgParams = (sourceParams.rg or {})
  local default = table.concat(rgParams.globs or {}, ' ')
  local globs = vim.split(vim.fn.input('rg globs: ', default), '%s+', { trimempty = true })
  vim.fn['ddu#ui#multi_actions']({
    { 'updateOptions', { sourceParams = { rg = { globs = globs } } } },
    { 'redraw', { method = 'refreshItems' } }
  })
end, {buffer=true, desc="DDU: ripgrep globs"}) -- }}}

-- }}}

EOF
-- }}}

