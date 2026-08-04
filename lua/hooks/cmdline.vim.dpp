-- lua_add {{{
-- Close the floating cmdline window, then send the real <CR>.
-- NOTE: `cmdline#disable()` is a no-op when the float is not open, so this
-- mapping is safe even if `cmdline#enable()` was not called (e.g. plain `:`
-- without `;;`).
vim.keymap.set('c', '<CR>', function()
  vim.cmd('call cmdline#disable()')
  return '<CR>'
end, { expr = true, silent = true })
-- }}}

-- lua_source {{{
local function set_cmdline_highlights()
  local ok, colors = pcall(function()
    return require('catppuccin.palettes').get_palette()
  end)
  if ok then
    vim.api.nvim_set_hl(0, 'CmdlineFloating', { bg = colors.base, fg = colors.text })
  else
    vim.api.nvim_set_hl(0, 'CmdlineFloating', { bg = '#000000', fg = '#cdd6f4' })
  end
end

set_cmdline_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.g['vimrc#augroup'],
  callback = set_cmdline_highlights,
})

vim.fn['cmdline#set_option']({
  highlight_window = 'CmdlineFloating',
  blend = vim.o.pumblend,
})
-- }}}

