-- ROOT OF NVIM CONFIG FILES
local _info = debug.getinfo(1, 'S')
local sfile = _info and _info.source:sub(2)
local config_name = sfile and vim.fn.fnamemodify(sfile, ':p:h:t') or 'nvim'

local home_dir = vim.env.HOME or vim.fn.expand('~')

-- Define `vim.env.NVIM_DEBUG to enable debug mode.
-- Log-to-file setup lives in `lua/vimrc/debug.lua`.
local is_debug = vim.env.NVIM_DEBUG == 'true'
if is_debug then
  vim.g['vimrc#is_debug'] = true
  vim.g['denops#debug'] = 1
else
  vim.g['vimrc#is_debug'] = false
end

vim.g['vimrc#augroup'] = vim.api.nvim_create_augroup('vimrc', { clear = true })

local nvim_config_home =
  tostring(sfile and vim.fs.dirname(sfile) or vim.fn.stdpath('config'))
local nvim_cache_home = vim.fs.joinpath(
  vim.env.XDG_CACHE_HOME or vim.fs.joinpath(home_dir, '.cache'),
  config_name
)
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

vim.loader.enable()
local loader = vim.fn.expand('~/.cache/rvpm/nvim/plugins/loader.lua')
if vim.uv.fs_stat(loader) then
  dofile(loader)
end

vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
