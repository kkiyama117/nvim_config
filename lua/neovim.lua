-- For Neovim only workarounds

-- ==========================================================================
-- Disable default syntax loading an remote providers
-- ==========================================================================
-- Disable auto syntax loading
if vim.v.vim_starting == 1 and #vim.fn.argv() == 0 then
  vim.cmd('syntax off')
end

-- Disable providers of remote (plugin)
vim.g.loaded_node_provider = false
vim.g.loaded_perl_provider = false
vim.g.loaded_python_provider = false
vim.g.loaded_ruby_provider = false

-- Disable remote plugin loading
vim.g.loaded_remote_plugins = true

-- Python3 host prog
vim.g.python3_host_prog = vim.fn.has('win32') == 1 and 'python.exe' or 'python3'

-- ==========================================================================
-- WORKAROUNDS
-- ==========================================================================
-- Workaround for the flicker
-- https://github.com/neovim/neovim/issues/32660
-- https://blog.atusy.net/2025/05/07/workaround-nvim-async-ts-fliker/
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinNew', 'WinClosed', 'TabEnter' }, {
  group = vim.api.nvim_create_augroup('ts_toggle_sync_parsing', {}),
  callback = function(ctx)
    local function exec()
      local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
      local bufs = {}
      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        if bufs[buf] == true then
          local parsable = pcall(vim.treesitter.get_parser, buf)
          if parsable then
            vim.g._ts_force_sync_parsing = true
            return
          end
          bufs[buf] = false
        end
        if bufs[buf] == nil then
          bufs[buf] = true
        end
      end
      vim.g._ts_force_sync_parsing = false
    end

    if ctx.event == 'WinClosed' then
      return vim.schedule(exec)
    end
    return exec()
  end,
})


vim.api.nvim_create_autocmd('TermOpen', {
  pattern = '*',
  group = 'MyAutoCmd',
  command = 'setlocal modifiable',
})

vim.g.terminal_scrollback_buffer_size = 3000

vim.api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function()
    vim.hl.hl_op({ higroup = 'IncSearch', timeout = 200 })
  end,
})

-- ==========================================================================
-- Treesitter configs
-- ==========================================================================
-- NOTE: Disable treesitter async parsing
-- https://github.com/neovim/neovim/pull/31631
-- https://github.com/neovim/neovim/pull/33145
-- vim.g._ts_force_sync_parsing = true
local function config_treesitter()
  vim.treesitter.start = (function(wrapped)
    return function(bufnr, lang)
      local disables_ft = { 'help' }
      local disables_lang = { 'diff', 'latex' }

      local ft = vim.fn.getbufvar(bufnr or vim.fn.bufnr(''), '&filetype')
      if vim.tbl_contains(disables_ft, ft) or vim.tbl_contains(disables_lang, lang) then
        return
      end

      if bufnr then
        local max_filesize = 50 * 1024
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size > max_filesize then
          return
        end
      end

      wrapped(bufnr, lang)
    end
  end)(vim.treesitter.start)
end

vim.api.nvim_create_autocmd('Syntax', {
  group = 'MyAutoCmd',
  once = true,
  callback = config_treesitter,
})

-- ==========================================================================
-- GUI and UI2
-- ==========================================================================
-- Enable virtual_lines feature
-- vim.diagnostic.config({ virtual_lines = { current_line = true } })

if vim.fn.exists('g:neovide') == 1 then
  vim.g.neovide_no_idle = true
  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_cursor_trail_length = 0
  vim.g.neovide_hide_mouse_when_typing = true
end

-- Use PlemolJP
if vim.fn.has('win32') == 1 then
  vim.opt.guifont = 'PlemolJP:h13'
else
  vim.opt.guifont = 'PlemolJP:h10'
end

--[[
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
if #vim.api.nvim_list_uis() > 0 and not enable_ui2() then
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
--]]
