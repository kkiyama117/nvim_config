-- For Neovim only workarounds
local myAuGroup =
  vim.api.nvim_create_augroup('vimrc#augroup', { clear = false })

-- Disable auto syntax loading {{{
if vim.v.vim_starting == 1 and #vim.fn.argv() == 0 then
  vim.cmd('syntax off')
end

-- Disable providers of remote (plugin)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Disable remote plugin loading
vim.g.loaded_remote_plugins = true

-- Python3 host prog
vim.g.python3_host_prog = vim.fn.has('win32') == 1 and 'python.exe' or 'python3'
-- }}}

-- ==========================================================================
-- WORKAROUNDS
-- ==========================================================================
-- Workaround for the flicker {{{
-- https://github.com/neovim/neovim/issues/32660
-- https://blog.atusy.net/2025/05/07/workaround-nvim-async-ts-fliker/
vim.api.nvim_create_autocmd(
  { 'BufWinEnter', 'WinNew', 'WinClosed', 'TabEnter' },
  {
    group = vim.api.nvim_create_augroup('ts_toggle_sync_parsing', {}),
    callback = function(ctx)
      local function exec()
        local wins =
          vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
        local bufs = {}
        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          if bufs[buf] == nil then
            bufs[buf] = true
            local ok, parsable = pcall(vim.treesitter.get_parser, buf)
            if ok and parsable then
              vim.g._ts_force_sync_parsing = true
              return
            end
          end
        end
        vim.g._ts_force_sync_parsing = false
      end

      if ctx.event == 'WinClosed' then
        return vim.schedule(exec)
      end
      return exec()
    end,
  }
)
-- }}}

-- Disable Treesitter by default; re-enabled when tree-sitter-manager.nvim is sourced.
-- If dpp load_state fails, the plugin never loads and Treesitter stays off,
-- avoiding "No parser for language" errors from built-in ftplugins.
vim.treesitter.start = function() end

-- Modifiable terminal {{{
vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  group = myAuGroup,
  command = 'setlocal modifiable',
})

vim.g.terminal_scrollback_buffer_size = 3000

vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  group = myAuGroup,
  callback = function()
    vim.hl.hl_op({ higroup = 'IncSearch', timeout = 200 })
  end,
})
-- }}}



-- Enable virtual_lines feature
vim.diagnostic.config({ virtual_lines = { current_line = true } })

-- Config for neovide {{{
if vim.fn.exists('g:neovide') == 1 then
  vim.g.neovide_no_idle = true
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_length = 0
  vim.g.neovide_hide_mouse_when_typing = true
end
-- }}}

-- Use PlemolJP for guifont {{{
if vim.fn.has('win32') == 1 then
  vim.opt.guifont = 'PlemolJP:h13'
else
  vim.opt.guifont = 'PlemolJP:h10'
end
-- }}}

-- nvim UI2 {{{
-- NOTE: Disabled.  The new `ui2` message handler in nvim 0.13-dev raises
-- `Invalid 'end_col': out of range` in `vim/_core/ui2/messages.lua:237`
-- when messages are shown (an extmark copied src->tgt gets an end_col
-- beyond the target line length).  Keeping `vim.g._ui2_enabled` falsy
-- makes `enable_ui2()` short-circuit and leaves the classic message UI.
-- To re-enable: remove the `false and` guard below (and this note).
vim.g._ui2_enabled = false

local function enable_ui2()
  if #vim.api.nvim_list_uis() == 0 or vim.g._ui2_enabled then
    return true
  end
  pcall(vim.treesitter.language.add, 'vim')
  if not pcall(vim.treesitter.get_string_parser, '', 'vim') then
    return false
  end
  require('vim._core.ui2').enable({})
  vim.g._ui2_enabled = true
  return true
end

-- Enable `UI2` if it can be used.
if false and #vim.api.nvim_list_uis() > 0 and not enable_ui2() then
  local group = vim.api.nvim_create_augroup('enable_ui2', { clear = true })
  vim.api.nvim_create_autocmd({ 'VimEnter', 'CursorHold' }, {
    group = group,
    callback = function()
      if enable_ui2() then
        vim.api.nvim_del_augroup_by_id(group)
      end
    end,
  })
end
-- }}}

