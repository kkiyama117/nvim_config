-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.
vim.keymap.set({ 'i', 'c', 't' }, '<C-j>', '<Plug>(skkeleton-toggle)')
vim.keymap.set('n', '<C-j>', 'i<Plug>(skkeleton-enable)')
-- }}}

-- lua_source {{{
-- vim.g["skkeleton#debug"] = true
-- Script-local state: saved cursor highlight (table for Neovim, list for Vim)
local hl_cursor = nil

-- --------------------------------------------------------------------------
-- highlight_cursor (shared helper)
-- --------------------------------------------------------------------------
local function highlight_cursor(highlight)
  local is_cmdline = vim.fn.exists('*cmdline#_get') == 1 and not vim.tbl_isempty(vim.fn['cmdline#_get']().pos)
  local highlight_name = is_cmdline and 'CmdlineCursor' or 'Cursor'

  if vim.fn.has('nvim') == 1 then
    vim.api.nvim_set_hl(0, highlight_name, highlight)
  else
    highlight[1].name = highlight_name
    vim.fn.hlset(highlight)
  end

  -- NOTE: redraw is needed
  vim.cmd('redraw')
end

-- --------------------------------------------------------------------------
-- skkeleton_changed (shared between mode-changed and handled)
-- --------------------------------------------------------------------------
local function skkeleton_changed()
  -- Change the cursor color
  local hl = vim.deepcopy(hl_cursor)

  local mode = vim.g['skkeleton#mode']
  local color
  if mode == 'hira' then
    color = '#80403f'
  elseif mode == 'kata' then
    color = '#f04060'
  elseif mode == 'hankata' then
    color = '#60a060'
  elseif mode == 'zenkaku' then
    color = '#60c060'
  elseif mode == 'abbrev' then
    color = '#60f060'
  else
    color = '#606060'
  end

  if vim.fn.has('nvim') == 1 then
    hl.bg = color
  else
    hl[1].guibg = color
  end

  highlight_cursor(hl)
end

-- --------------------------------------------------------------------------
-- skkeleton#config
-- --------------------------------------------------------------------------
local skk_jisho_path = vim.fn.expand('$XDG_STATE_HOME' .. '/SKK-JISYO.L')
vim.fn['skkeleton#config']({
  databasePath = vim.fn.expand('~/.cache/skkeleton.db'),
  eggLikeNewline = true,
  globalDictionaries = vim.fn.has('win32') == 1 and { skk_jisho_path } or { '/usr/share/skk/SKK-JISYO.L' },
  markerHenkan = '',
  markerHenkanSelect = '',
  registerConvertResult = true,
  sources = {
    'deno_kv',
    'google_japanese_input',
  },
})

-- For SKK server test.
-- vim.fn['skkeleton#config']({
--   sources = {
--     'skk_dictionary',
--     'skk_server',
--   },
-- })

-- --------------------------------------------------------------------------
-- skkeleton#register_kanatable
-- --------------------------------------------------------------------------
vim.fn['skkeleton#register_kanatable']('rom', {
  jj = 'escape',
  ['~'] = { '〜', '' },
})

-- --------------------------------------------------------------------------
-- Autocmd: skkeleton-enable-pre
-- --------------------------------------------------------------------------
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-enable-pre',
  group = 'MyAutoCmd',
  callback = function()
    if (vim.fn.has('nvim') ~= 1 or vim.env.DISPLAY ~= '') and vim.fn.has('clipboard') == 1 then
      -- Copy to clipboard to use Vim as IME
      vim.api.nvim_create_autocmd('ModeChanged', {
        pattern = '*:n',
        group = 'MyAutoCmd',
        once = true,
        callback = function()
          vim.fn.setreg('*', vim.fn.getline('.'))
          vim.fn.setreg('+', vim.fn.getreg('*'))
        end,
      })
    end

    local is_cmdline = vim.fn.exists('*cmdline#_get') == 1 and not vim.tbl_isempty(vim.fn['cmdline#_get']().pos)
    local hl_name = is_cmdline and 'CmdlineCursor' or 'Cursor'

    if vim.fn.has('nvim') == 1 then
      hl_cursor = vim.api.nvim_get_hl(0, { name = hl_name })
    else
      hl_cursor = vim.fn.hlget(hl_name)
    end
  end,
})

-- --------------------------------------------------------------------------
-- Autocmd: skkeleton-mode-changed
-- --------------------------------------------------------------------------
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-mode-changed',
  group = 'MyAutoCmd',
  callback = skkeleton_changed,
})

-- --------------------------------------------------------------------------
-- Autocmd: skkeleton-handled
-- --------------------------------------------------------------------------
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-handled',
  group = 'MyAutoCmd',
  callback = function()
    if vim.g['skkeleton#mode'] == '' then
      return
    end

    -- Change the cursor color
    local phase = vim.g['skkeleton#state'].phase
    if phase == 'henkan' or phase == 'input:okurinasi' or phase == 'input:okuriari' then
      local hl = vim.deepcopy(hl_cursor)
      local color = '#a0f0a0'
      if vim.fn.has('nvim') == 1 then
        hl.bg = color
      else
        hl[1].guibg = color
      end
      highlight_cursor(hl)
    else
      skkeleton_changed()
    end
  end,
})

-- --------------------------------------------------------------------------
-- skkeleton_state_popup#config
-- --------------------------------------------------------------------------
vim.fn['skkeleton_state_popup#config']({
  labels = {
    input = {
      hira = 'あ',
      kata = 'ア',
      hankata = 'ｶﾅ',
      zenkaku = 'Ａ',
    },
    ['input:okurinasi'] = {
      hira = '▽',
      kata = '▽',
      hankata = '▽',
      abbrev = 'ab',
    },
    ['input:okuriari'] = {
      hira = '▽',
      kata = '▽',
      hankata = '▽',
    },
    henkan = {
      hira = '▼',
      kata = '▼',
      hankata = '▼',
      abbrev = 'ab',
    },
  },
  opts = {
    relative = 'cursor',
    col = 0,
    row = 1,
    anchor = 'NW',
    style = 'minimal',
  },
})

vim.fn['skkeleton_state_popup#enable']()
vim.fn['skkeleton#initialize']()
-- }}}

