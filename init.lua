-- $VIMRUNTIME/defaults.vim is skipped in /etc/vimrc

-- new vim loader for bite code cache
if vim.loader then
  vim.loader.enable()
end

-----------------------------------------------------------------------------
-- DEBUG MODE config
-----------------------------------------------------------------------------
-- Define `vim.env.NVIM_DEBUG to enable debug mode.
local is_debug = vim.env.NVIM_DEBUG == 'true'

-- verbose level set to 3 {{{
if vim.env.NVIM_DEBUG == 'true' then
  vim.o.verbose = 3 -- increase verbosity in debug mode
  vim.notify('[DEBUG] DEBUG MODE ENABLED', vim.log.levels.DEBUG)
  vim.notify(('$NVIM_DEBUG: %s'):format(vim.env.NVIM_DEBUG), vim.log.levels.WARN)
end
-- }}}

-----------------------------------------------------------------------------
-- General ENVIRONMENT VARIABLES
-----------------------------------------------------------------------------
-- Default `MyAutoCmd`
myautocmd = vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

-- ENVIRONMENT VARIABLES with neovim {{{
-- STDPATH {{{
vim.g.nvim_config_home = vim.fn.stdpath('config')
vim.env.NVIM_CONFIG_HOME = vim.g.nvim_config_home
vim.g.nvim_cache_home = vim.fn.stdpath('cache')
vim.env.NVIM_CACHE_HOME = vim.g.nvim_cache_home
-- }}}

-- RUNTIMEPATH {{{
vim.opt.runtimepath = table.concat({
  vim.g.nvim_config_home,
  vim.g.nvim_config_home .. '/local',
  vim.o.runtimepath,
  vim.g.nvim_config_home .. '/after',
  vim.g.nvim_config_home .. '/local/after',
}, ',')
-- }}}

-- Deno binary path for denops
vim.g['denops#deno'] = vim.env.MISE_DATA_DIR .. '/installs/deno/latest/bin/deno' or 'deno'
-- }}}

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
-- {{{
-- Use `dpp` as a default
if is_debug then
  vim.notify('[DEBUG] dpp_loader start', vim.log.levels.DEBUG)
end
require('dpp_loader')
if is_debug then
  vim.notify('[DEBUG] dpp_loader end', vim.log.levels.DEBUG)
end
-- }}}

vim.cmd('filetype indent plugin on')
vim.cmd('syntax on')

if is_debug then
  vim.notify('loaded $NVIM_CONFIG_HOME/init.lua')
end

