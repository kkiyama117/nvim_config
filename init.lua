-- $VIMRUNTIME/defaults.vim is skipped in /etc/vimrc

-- new vim loader for bite code cache
if vim.loader then
  vim.loader.enable()
end

-----------------------------------------------------------------------------
-- General ENVIRONMENT VARIABLES
-----------------------------------------------------------------------------
-- ENVIRONMENT VARIABLES with neovim {{{
-- STDPATH {{{
vim.g.nvim_config_home = vim.fn.stdpath('config')
vim.env.NVIM_CONFIG_HOME = vim.g.nvim_config_home
vim.g.nvim_cache_home = vim.fn.stdpath('cache')
vim.env.NVIM_CACHE_HOME = vim.g.nvim_cache_home
-- }}}

-- Deno binary path for denops
vim.g['denops#deno'] = vim.env.MISE_DATA_DIR .. '/installs/deno/latest/bin/deno' or 'deno'
-- }}}

-----------------------------------------------------------------------------
-- DEBUG MODE config
-----------------------------------------------------------------------------
-- Define `vim.env.NVIM_DEBUG to enable debug mode. {{{
if vim.env.NVIM_DEBUG == 'true' then
  vim.o.verbose = 3 -- increase verbosity in debug mode
  vim.notify('[DEBUG] init.lua loaded', vim.log.levels.DEBUG)
  vim.notify(('$NVIM_DEBUG: %s'):format(vim.env.NVIM_DEBUG), vim.log.levels.WARN)
end
-- }}}

-- Default `MyAutoCmd`
myautocmd = vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

-- vim.api.nvim_create_autocmd({"filetype","syntax","bufnewfile","bufnew","bufread"}, {
--   pattern = "*?",
--   group = "myautocmd",
--   command = [[ call vimrc#on_filetype() ]]
-- })

-- LANG {{{
if vim.fn.has('unix') then
  vim.env.LANG = 'ja_JP.UTF_8'
else
  vim.env.LANG = 'ja'
end
-- vim.fn.language(vim.env.LANG)
vim.opt.langmenu = vim.env.LANG
-- }}}

-----------------------------------------------------------------------------
-- LOAD OTHER SETTING FILES (ex. loader of dpp.vim):
-----------------------------------------------------------------------------
-- Use `dpp` as a default
require('dpp_loader')

vim.cmd('filetype indent plugin on')
vim.cmd('syntax on')

if vim.env.NVIM_DEBUG == 'true' then
  vim.notify('loaded $NVIM_CONFIG_HOME/init.lua')
end

