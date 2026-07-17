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
vim.fn['cmdline#set_option']({ highlight_window = 'None' })
-- }}}
