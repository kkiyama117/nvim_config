if vim.loader then
  vim.loader.enable()
end

-- Define `vim.env.NVIM_DEBUG to enable debug mode.
local is_debug = vim.env.NVIM_DEBUG == 'true'
-- verbose level set to 3 {{{
if vim.env.NVIM_DEBUG == 'true' then
  vim.o.verbose = 3 -- increase verbosity in debug mode
  vim.notify('[DEBUG] DEBUG MODE ENABLED', vim.log.levels.DEBUG)
  vim.notify(('$NVIM_DEBUG: %s'):format(vim.env.NVIM_DEBUG), vim.log.levels.WARN)
end
-- }}}

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

-- LANG {{{
if vim.fn.has('unix') then
  vim.env.LANG = 'ja_JP.UTF_8'
else
  vim.env.LANG = 'ja'
end
-- vim.fn.language(vim.env.LANG)
vim.opt.langmenu = vim.env.LANG
-- }}}

-- LOAD OTHER SETTING FILES (ex. loader of dpp.vim):
-- TODO: `if !v:vim_did_enter` を入れる.
require('dpp_loader')

vim.cmd('filetype indent plugin on')
vim.cmd('syntax on')

-- Disable default plugins {{{
-- dpp.vim manages plugins itself; no need for Vim's built-in packpath. (Really???)
vim.opt.packpath = ''
local save_rtp = vim.opt.runtimepath
-- TODO: do like `kuuote` does; like below
-- vim.opt.runtimepath:remove(vim.env.VIMRUNTIME)
-- vim.api.nvim_create_autocmd('SourcePre', {
--   pattern = '*/plugin/*',
--   group = 'MyAutoCmd',
--   once = true,
--   callback = function()
--     vim.o.runtimepath = save_rtp
--   end,
-- })
if is_debug then
  vim.notify_once('[DEBUG]: Default plugins disabled')
end
-- }}}

if is_debug then
  vim.notify('loaded $NVIM_CONFIG_HOME/init.lua', vim.log.levels.DEBUG)
end

