local vimrc = require('vimrc')
-- =========================================================================
-- Keys defined by `options`
-- =========================================================================
-- Insert {{{
-- BackSpace
vim.opt.backspace = 'indent,eol,nostop'
-- }}}
-- Terminal {{{
if vim.fn.exists('+termwinkey') == 1 then
  vim.opt.termwinkey = '<C-L>'
end
-- }}}
-- Commandline (CmdLine) {{{
-- Cedit
vim.opt.cedit = '<C-s>'
-- Wild mode key; <C-t> {{{
vim.opt.wildchar = 20
vim.opt.wildcharm = 20
-- }}}
-- Commandline Better <C-w> deletion {{{
-- TODO: Check it can work well.
local save_iskeyword

vim.api.nvim_create_autocmd('CmdlineEnter', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function()
    save_iskeyword = vim.bo.iskeyword
    vim.bo.iskeyword = vim.bo.iskeyword .. ',.,-,+,/,:'
  end,
})

vim.api.nvim_create_autocmd('CmdlineLeave', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function()
    if save_iskeyword then
      vim.bo.iskeyword = save_iskeyword
    end
  end,
})
-- }}}
-- }}}
-- }}}

-- ==========================================================================
-- <Leader> key (and <LocalLeader>)
-- ==========================================================================
-- candidates are `<Space>`, `,`, `s`, `t`, `m`,
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

-- ==========================================================================
-- Custom keys (without plugins)
-- ==========================================================================
-- No operation keys {{{1
vim.keymap.set({ 'n' }, 'ZZ', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, 'ZQ', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, 'M', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, 'Q', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, '<Left>', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, '<Right>', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, '<Up>', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, '<Down>', '<Nop>', { silent = true })
-- }}}
-- Overrided keys {{{1
-- <Leader> and <LocalLeader>
vim.keymap.set({ 'n', 'x' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set({ 'n', 'x' }, ',', '<Nop>', { silent = true })
-- Other mappings
vim.keymap.set({ 'n' }, 's', '<Nop>', { silent = true })
-- convert `;` and `:`, with `cmdline.nvim`. See @lua/hooks/ddc.vim.lua
vim.keymap.set({ 'n' }, ';', '<Nop>', { silent = true })
vim.keymap.set({ 'n' }, ':', '<Nop>', { silent = true })
-- Use `q` as prefix key, with only `m`/`M` registers for macro recording.
-- Based on [this](https://zenn.dev/vim_jp/articles/29d021fff07e60)
vim.keymap.set({ 'n' }, 'q', '<Nop>', { silent = true })

-- }}}
-- Manual indents {{{1
vim.keymap.set({ 'n' }, '>', '>>')
vim.keymap.set({ 'n' }, '<', '<<')
vim.keymap.set({ 'x' }, '>', '>gv')
vim.keymap.set({ 'x' }, '<', '<gv')
-- }}}
-- Insert mode undo key{{{1
vim.keymap.set({ 'i' }, '<C-w>', '<C-g>u<C-w>')
vim.keymap.set({ 'i' }, '<C-u>', '<C-g>u<C-u>')
-- }}}
-- Better x {{{1
vim.keymap.set('n', 'x', '_x')
-- }}}
-- ==========================================================================
-- Keys using `<Leader>`
-- ==========================================================================
-- Save only buffer is changed.
vim.keymap.set('n', '<Leader><Leader>', function() -- {{{
  vim.cmd('update')
end, { silent = true }) -- }}}

-- Quickfix
vim.keymap.set('n', '<Leader>q', function()
  -- {{{
  vimrc.diagnostics_to_location_list()
end, { silent = true })
-- }}}

-- Plugin mapped sub keys of `<Leader>`
-- Keymaps depends on user plugins are defined at
-- $NVIM_CONFIG_HOME/lua/hooks/(plugin).lua
-- {{{
-- `<Leader>d`=[DP]{{{
vim.keymap.set({ 'n' }, '<Leader>d', '[DP]', { remap = true })
vim.keymap.set({ 'n' }, '[DP]', '<Nop>')
-- }}}
-- `<Leader>T`=[TOGGLE]{{{
vim.keymap.set({ 'n' }, '<Leader>T', '[TOGGLE]', { remap = true })
vim.keymap.set({ 'n' }, '[TOGGLE]', '<Nop>')
-- }}}
-- }}}

-- Keys for [TOGGLE] options{{{
vim.keymap.set('n', '[TOGGLE]c', function()
  --TODO: FIX IT
  --vimrc.toggle_option('wrap')
end, { silent = true })
vim.keymap.set({ 'n' }, '[TOGGLE]s', function()
  vimrc.toggle_option('spell')
  vim.opt_local.spelllang = { 'en_us', 'cjk' }
end, { silent = true })
vim.keymap.set('n', '[TOGGLE]w', function()
  vimrc.toggle_option('wrap')
end, { silent = true })
-- }}}

-- ==========================================================================
-- Other 'Leader' key
-- ==========================================================================
-- q | smart quit settings except `m` and `M` buffer {{{
-- Default `q` macro settings (only `qm` or `qM`){{{
-- Start recording into `m` or `M` register
vim.keymap.set('n', 'qm', 'qm', { desc = 'start recording into m' })
vim.keymap.set('n', 'qM', 'qM', { desc = 'start recording into M' })
-- During recording, override `q` to stop immediately (buffer-local nowait).
-- Only `m`/`M` registers are allowed; any other register is rejected.
vim.api.nvim_create_autocmd('RecordingEnter', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function() -- {{{
    local reg = vim.fn.reg_recording()
    if reg ~= 'm' and reg ~= 'M' then
      vim.cmd('normal! q')
      return
    end

    local augroup_inner = vim.api.nvim_create_augroup('prefix-q-inner', {})
    local buffer = vim.api.nvim_get_current_buf()

    -- buffer-local q to stop recording immediately (overrides global <Nop>)
    vim.keymap.set('n', 'q', 'q', { nowait = true, buffer = buffer })

    -- Stop recording when leaving buffer/window
    vim.api.nvim_create_autocmd({ 'BufLeave', 'WinLeave' }, {
      pattern = '*',
      once = true,
      group = augroup_inner,
      callback = function()
        vim.cmd('normal! q')
        vim.notify('stop recording', vim.log.levels.INFO)
      end,
      desc = 'stop recording when leaving buffer',
    })

    -- Clean up on recording leave
    vim.api.nvim_create_autocmd('RecordingLeave', {
      pattern = '*',
      once = true,
      callback = function()
        vim.keymap.del('n', 'q', { buffer = buffer })
        vim.api.nvim_del_augroup_by_id(augroup_inner)
      end,
      desc = 'delete q mapping when recording leave',
    })
  end, -- }}}
})
-- }}}
-- smart quit {{{
-- normal smart quit
vim.keymap.set('n', 'qq', function() -- {{{
  if vim.fn.winnr('$') == 1 then
    vim.cmd('enew')
    return
  end
  -- Quickfix / location list window exist
  for winnr = 1, vim.fn.winnr('$') do
    local buftype = vim.fn.getbufvar(vim.fn.winbufnr(winnr), '&buftype')
    if buftype and buftype:find('quickfix') then
      vim.cmd('cclose')
      vim.cmd('lclose')
      return
    end
  end
  -- Previous window exist and not current one, close
  if vim.fn.winnr('#') > 0 and vim.fn.winnr('#') ~= vim.fn.winnr() then
    vim.cmd('close')
    return
  end
  -- if winfixbuf, do nothing
  if vim.fn.getwinvar(vim.fn.winnr(), '&winfixbuf') ~= 0 then
    return
  end
  -- default is `enew`
  vim.cmd('enew')
end, { desc = 'smart exit' }) -- }}}

-- Call `dpp#make_state` and then restart Nvim
vim.keymap.set('n', 'qr', function() -- {{{
  if vim.fn.exists(':restart') == 2 then
    if vim.fn.exists('*dpp#make_state') == 1 then
      -- Mark in-flight so VimLeavePre (filetype.lua) waits for
      -- `Dpp:makeStatePost` before `:restart`'s `:qall` kills the denops
      -- Deno process mid-write.  Cleared by the Dpp:makeStatePost autocmd
      -- registered in dpp_loader.lua.  Without this, :restart re-execs nvim
      -- before denops finishes writing state.vim/startup.vim, so the new
      -- nvim's `dpp#min#load_state` falls back to the slow DenopsReady path.
      vim.g.dpp_make_state_in_progress = true
      vim.fn['dpp#make_state']('~/.cache/dpp')
    end
    vim.cmd('restart +xall')
  else
    print('No RESTART COMMAND')
  end
end) -- }}}

-- Save, then call `qq`
vim.keymap.set('n', 'qw', ':<C-u>w<CR>qq', { desc = 'smart exit with saving' })

-- }}}
-- }}}

-- s | windows and buffers {{{1
local function next_window() -- {{{
  local wins = vim.api.nvim_tabpage_list_wins(0)
  local cur = vim.api.nvim_get_current_win()
  for i, win in ipairs(wins) do
    if win == cur then
      vim.api.nvim_set_current_win(wins[i % #wins + 1])
      return
    end
  end
end
-- }}}
-- check `lua/hooks/ddu.vim.lua` for other keymaps start from `s`
vim.keymap.set('n', 'sn', next_window)
vim.keymap.set('n', 'so', function()
  -- {{{
  vim.cmd('only')
end) -- }}}
vim.keymap.set('n', 'sp', function()
  -- {{{
  vim.cmd('vsplit')
  next_window()
end) -- }}}
vim.keymap.set('n', 'st', function()
  -- {{{
  vim.cmd('split')
end) -- }}}

-- Default search
vim.keymap.set('n', 's/', '/\\<\\%')
vim.keymap.set('n', 's?', '?\\<\\%')
-- }}}

-- Command line mode keymap {{{1
-- TODO: Add
-- }}}

-- ==========================================================================
-- MAPPINGS REFERENCE
-- ==========================================================================
-- Files that set plugin dependent custom mappings {{{
-- $NVIM_CONFIG_HOME/lua/hooks/agentic.nvim.lua
-- $NVIM_CONFIG_HOME/lua/hooks/ddc.vim.lua
-- $NVIM_CONFIG_HOME/lua/hooks/ddu.vim.lua
-- $NVIM_CONFIG_HOME/lua/hooks/ddu-ui-ff.lua
-- $NVIM_CONFIG_HOME/lua/hooks/ddu-ui-filer.lua
-- $NVIM_CONFIG_HOME/lua/hooks/skkeleton.lua
-- }}}
-- BUFFER-LOCAL MAPPINGS (FileType) {{{
-- ddu-ff {{{
-- lua/hooks/ddu-ui-ff.lua
-- }}}
-- ddu-filer {{{
-- lua/hooks/ddu-ui-filer.lua
-- }}}
-- }}}

