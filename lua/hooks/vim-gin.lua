-- lua_add {{{
vim.g.gin_proxy_disable_editor = true

-- mappings {{{
vim.keymap.set('n', '[GIT]S', function()
  vim.cmd.GinStatus()
end, { desc = 'Gin status' })
-- }}}

-- }}}

