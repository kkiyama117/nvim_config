-- $VIMRUNTIME/defaults.vim is skipped in /etc/vimrc
-- new vim loader
if vim.loader then
  vim.loader.enable()
end

-----------------------------------------------------------------------------
-- disable netrw at the very start of your init.lua
-----------------------------------------------------------------------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-----------------------------------------------------------------------------
-- General ENVIRONMENT VARIABLES
-----------------------------------------------------------------------------
vim.api.nvim_create_augroup('MyAutoCmd', { clear = true })

--" config home of nvim
vim.g.nvim_config_home = vim.api.nvim_call_function('fnamemodify',
  { vim.api.nvim_call_function("expand", { '<sfile>' }), ":p:h" })
vim.env.NVIM_CONFIG_HOME = vim.g.nvim_config_home

--" deno path to use denops
vim.g['denops#deno'] = vim.env.XDG_DATA_HOME .. '/mise' .. '/installs/deno/latest/bin/deno' or 'deno'

--" LANG
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
-- load lua files
local dpp = require('dpp_loader')
dpp.setup()

-- Neovim default
--vim.cmd("filetype indent plugin on")
--vim.opt.syntax = "on"

