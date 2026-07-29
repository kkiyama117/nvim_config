-- ROOT OF NVIM CONFIG FILES

-- Define `vim.env.NVIM_DEBUG to enable debug mode. {{{
-- TODO: make `switcher` to toggle `NVIM_DEBUG`
local is_debug = vim.env.NVIM_DEBUG == 'true'
-- verbose level set to 3 {{{
if vim.env.NVIM_DEBUG == 'true' then
  vim.o.verbose = 3 -- increase verbosity in debug mode
  vim.notify('[DEBUG] DEBUG MODE ENABLED', vim.log.levels.DEBUG)
  vim.notify(('$NVIM_DEBUG: %s'):format(vim.env.NVIM_DEBUG), vim.log.levels.WARN)
end
-- }}}
-- }}}

-- Default `MyAutoCmd`
myautocmd = vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

-- ENVIRONMENT VARIABLES with neovim {{{
-- STDPATH {{{
vim.g.home_dir = vim.env.HOME
-- XDG{{{
vim.g.xdg_cache_home = vim.env.XDG_CACHE_HOME or vim.fn.fnamemodify(vim.g.home_dir, ':p:h') .. '/.cache'
vim.g.xdg_config_home = vim.env.XDG_CONFIG_HOME or vim.fn.fnamemodify(vim.g.home_dir, ':p:h') .. '/.config'
-- }}}
-- NVIM{{{
vim.g.nvim_config_home = vim.fn.stdpath('config')
vim.env.NVIM_CONFIG_HOME = vim.g.nvim_config_home
vim.g.nvim_cache_home = vim.fn.stdpath('cache')
vim.env.NVIM_CACHE_HOME = vim.g.nvim_cache_home
-- }}}
-- DPP{{{
-- cache of dpp
-- They should be matched with `dpp-ext` plugins
vim.g.dpp_cache_home = vim.fs.joinpath(vim.g.xdg_cache_home, 'dpp')
vim.g.dpp_cache_github = vim.fs.joinpath(vim.g.dpp_cache_home, 'repos', 'github.com')
vim.g.dpp_cache_local = vim.fs.joinpath(vim.g.dpp_cache_home, 'local')
--local dpp_denops_script = vim.fs.joinpath(vim.g.nvim_config_home, 'denops', 'dpp.ts')
--
-- }}}
-- }}}

-- minimum RUNTIMEPATH {{{
vim.opt.runtimepath = table.concat({
  vim.g.nvim_config_home,
  vim.g.nvim_config_home .. '/local',
  vim.o.runtimepath,
  vim.g.nvim_config_home .. '/after',
  vim.g.nvim_config_home .. '/local/after',
}, ',')
-- }}}
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
-- use dpp
-- require('bootloader')

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

