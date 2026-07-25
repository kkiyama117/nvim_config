-- Filetype-specific indent settings
-- lua {{{
lua << EOF
  vim.bo.shiftwidth = 2
  vim.bo.softtabstop = 2
  vim.bo.expandtab = true
  vim.bo.tabstop = 2
  -- Disable automatically insert comment.
  vim.opt_local.formatoptions:remove({ 't', 'c', 'r', 'o' })
  vim.opt_local.formatoptions:append({ 'm', 'M', 'B', 'l' })
  if vim.bo.textwidth ~= 70 and vim.bo.filetype ~= 'help' then
    vim.bo.textwidth = 0
  end
EOF
-- }}}

-- python {{{
lua << EOF
  vim.bo.softtabstop = 4
  vim.bo.shiftwidth = 4
  vim.bo.tabstop = 4
  vim.bo.textwidth = 80
  vim.bo.smarttab = true
  vim.bo.expandtab = true
EOF
-- }}}

-- vim {{{
lua << EOF
  vim.bo.softtabstop = 2
  vim.bo.shiftwidth = 2
  vim.bo.tabstop = 2
  vim.bo.textwidth = 78
EOF
-- }}}

