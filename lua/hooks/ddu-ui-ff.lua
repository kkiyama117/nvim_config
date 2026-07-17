-- lua_ddu-ff {{{
-- Coufig with fuzzy finder UI of `ddu.vim`
-- "ddu-ui-ff" buffer is typed as `ddu-ff`

-- ==========================================================================
-- KEYMAPS
-- ==========================================================================
vim.keymap.set('n', '<CR>', function()
  local item = vim.fn['ddu#ui#get_item']() or {}
  local action = item.action or {}
  local is_directory = action.isDirectory == true
  local params = is_directory and { name = 'narrow' } or { name = 'default' }
  vim.fn['ddu#ui#do_action']('itemAction', params)
end, { buffer = true })
vim.keymap.set('n', 'i', function()
  vim.fn['ddu#ui#do_action']('openFilterWindow')
end,{ buffer = true })
vim.keymap.set('n', 'q', function()
  vim.fn['ddu#ui#do_action']('quit')
end)
-- }}}
