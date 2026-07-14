-- lua_ {{{
  -- expand tab
  vim.opt_local.shiftwidth = 2
  vim.bo.expandtab = true
  -- " Disable automatically insert comment.
  vim.opt.formatoptions:remove({ "t", "c", "r", "o" })
  vim.opt.formatoptions:append({ "m", "M", "B", "l" })
  if vim.bo.textwidth ~= 70 and vim.bo.filetype ~= "help" then
    vim.bo.textwidth = 0
  end
-- }}}

-- TODO: Add each filetype

-- lua_python {{{
vim.opt_local.shiftwidth = 4
vim.opt_local.textwidth = 80
vim.bo.expandtab = true
-- }}}
