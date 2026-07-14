-- $VIMRUNTIME/defaults.vim is skipped in /etc/vimrc

-- new vim loader for bite code cache
if vim.loader then
  vim.loader.enable()
end

-----------------------------------------------------------------------------
-- General ENVIRONMENT VARIABLES
-----------------------------------------------------------------------------
--" config home for nvim
vim.g.nvim_config_home = vim.api.nvim_call_function('fnamemodify',
  { vim.api.nvim_call_function("expand", { '<sfile>' }), ":p:h" })
vim.env.NVIM_CONFIG_HOME = vim.g.nvim_config_home

vim.g.python3_host_prog = vim.env.MISE_DATA_DIR .. '/installs/python/latest/bin/python' or 'python3'
vim.g['denops#deno'] = vim.env.MISE_DATA_DIR .. '/installs/deno/latest/bin/deno' or 'deno'

vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })
-- vim.api.nvim_create_autocmd({"filetype","syntax","bufnewfile","bufnew","bufread"}, {
--   pattern = "*?",
--   group = "myautocmd",
--   command = [[ call vimrc#on_filetype() ]]
-- })

-- LANG
if vim.fn.has('unix') then
  vim.env.LANG = 'ja_JP.UTF_8'
else
  vim.env.LANG = 'ja'
end
--vim.fn.language(vim.env.LANG)
vim.opt.langmenu = vim.env.LANG

-----------------------------------------------------------------------------
-- LOAD OTHER SETTING FILES (ex. loader of dpp.vim):
-----------------------------------------------------------------------------
-- Use `dpp` as a default
require('dpp_loader')

vim.cmd("filetype indent plugin on")
vim.cmd("syntax on")
