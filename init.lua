-- ROOT OF NVIM CONFIG FILES
-- DO LIKE `<sfile>`, I hate this way to represent `sfile`, but it is the way to do this.
local _info = debug.getinfo(1, 'S')
local sfile = _info and _info.source:sub(2)
local config_name = sfile and vim.fn.fnamemodify(sfile, ':p:h:t') or 'nvim'

local home_dir = vim.env.HOME or vim.fn.expand('~')

-- Define `vim.env.NVIM_DEBUG to enable debug mode. {{{
local is_debug = vim.env.NVIM_DEBUG == 'true'
if is_debug then
  -- vim.o.verbose = 3 -- increase verbosity in debug mode
  vim.g['vimrc#is_debug'] = true
  vim.notify('[VIMRC]: DEBUG MODE ENABLED', vim.log.levels.DEBUG)
else
  vim.g['vimrc#is_debug'] = false
end
-- }}}

-- Default `MyAutoCmd`
vim.g['vimrc#augroup'] = vim.api.nvim_create_augroup('vimrc', { clear = true })

-- ENVIRONMENT VARIABLES with neovim {{{
-- use `<sfile>:p:h`, then fallback stdpath.
-- Fucking EmmyLua can't understand it `vim.fn.stdpath("string")` must be `string`, so round it `ToString`
local nvim_config_home =
  tostring(sfile and vim.fs.dirname(sfile) or vim.fn.stdpath('config'))
local nvim_cache_home = vim.fs.joinpath(
  vim.env.XDG_CACHE_HOME or vim.fs.joinpath(home_dir, '.cache'),
  config_name
)
-- SET AS ENV
vim.env.NVIM_CONFIG_HOME = nvim_config_home
vim.env.NVIM_CACHE_HOME = nvim_cache_home
if is_debug then
  vim.notify(
    ('[VIMRC]: NVIM_CONFIG_HOME=`%s`'):format(nvim_config_home),
    vim.log.levels.DEBUG
  )
  vim.notify(
    ('[VIMRC]: NVIM_CACHE_HOME=`%s`'):format(nvim_cache_home),
    vim.log.levels.DEBUG
  )
end
-- }}}

-- minimum RUNTIMEPATH {{{
-- Filter out non-existent directories to avoid E5009: Invalid 'runtimepath'
vim.opt.runtimepath = {
  nvim_config_home,
  --vim.fs.joinpath(nvim_config_home, "local"),
  vim.env.VIMRUNTIME,
  vim.fs.joinpath(nvim_config_home, 'after'),
  -- vim.fs.joinpath(nvim_config_home, "local/after"),
} -- }}}

-- call dpp.vim to load configs
if vim.v.vim_did_enter ~= true then
  require('bootloader').startup()
end

vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')

-- Remove VIMRUNTIME from runtimepath and clear packpath to prevent sourcing
-- default plugins before dpp decides what to load.
-- Restored on the first plugin file sourced (SourcePre), or at the latest on
-- VimEnter, so `$VIMRUNTIME`-dependent features (e.g. :checkhealth) don't
-- break with E5009 when no `plugin/*` file ever gets sourced.
local save_rtp = vim.o.runtimepath
local save_packpath = vim.o.packpath
vim.opt.packpath = ''
vim.opt.runtimepath:remove(vim.env.VIMRUNTIME)

local runtime_restored = false
local function restore_runtime()
  if runtime_restored then
    return
  end
  runtime_restored = true
  vim.o.runtimepath = save_rtp
  vim.o.packpath = save_packpath
end

vim.api.nvim_create_autocmd('SourcePre', {
  pattern = '*/plugin/*',
  group = vim.g['vimrc#augroup'],
  once = true,
  callback = restore_runtime,
})

-- TODO: remove this if it already unnessesary.
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.g['vimrc#augroup'],
  once = true,
  callback = function()
    vim.schedule(restore_runtime)
  end,
})
-- }}}

