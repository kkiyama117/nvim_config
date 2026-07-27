-- lua_add {{{
--vim.notify('vim-sandwich is added')
vim.keymap.set({ 'n', 'x' }, 'sa', '<Plug>(sandwich-add)', { desc = 'add `sandwich`' })
vim.keymap.set('x', 'sc', '<Plug>(sandwich-delete)', { desc = 'delete `sandwich` (manual)' })
vim.keymap.set({ 'n', 'x' }, 'sd', '<Plug>(sandwich-delete-auto)', { desc = 'delete `sandwich`' })
vim.keymap.set({ 'n', 'x' }, 'sr', '<Plug>(sandwich-delete-auto)', { desc = 'replace `sandwich`' })
-- }}}

