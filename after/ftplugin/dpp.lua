-- Filetype plugin for dpp.vim hooks files (*.dpp): Lua-like editing.
-- See .agents/issues/dpp-filetype.md

-- Lua-ish indentation (mirror the `lua` entry in lua/hooks/ft.dpp)
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2
vim.bo.expandtab = true

-- Lua-style comments
vim.bo.commentstring = '-- %s'

-- Hook blocks fold via the `{{{` / `}}}` markers (dpp's hooksFileMarker).
vim.opt_local.foldmethod = 'marker'
vim.opt_local.foldmarker = '{{{,}}}'
vim.opt_local.foldlevelstart = 99
