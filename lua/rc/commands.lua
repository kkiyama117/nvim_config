-- command list not depends on lazy loaded plugins

-- Command group opening with a specific character code again.
-- In particular effective when I am garbled in a terminal.
-- Open in UTF-8 again.
vim.api.nvim_create_user_command('Utf8', [[edit<bang> ++enc=utf-8 <args>]], {nargs='?', bang=true, bar=true,complete='file'})
vim.api.nvim_create_user_command('Cp932', [[edit<bang> ++enc=cp932 <args>]], {nargs='?', bang=true, bar=true,complete='file'})
vim.api.nvim_create_user_command('Iso2022jp', [[edit<bang> ++enc=iso-2022-jp <args>]], {nargs='?', bang=true, bar=true,complete='file'})
vim.api.nvim_create_user_command('Eucjp', [[edit<bang> ++enc=euc-jp <args>]], {nargs='?', bang=true, bar=true,complete='file'})
vim.api.nvim_create_user_command('Utf16', [[edit<bang> ++enc=ucs-2le <args>]], {nargs='?', bang=true, bar=true,complete='file'})


-- opt.args
-- Tried to make a file note version.
vim.api.nvim_create_user_command('WUtf8', function(opts) vim.opt_local.fenc='utf-8' end, {})
vim.api.nvim_create_user_command('WCp932', function(opts) vim.opt_local.fenc='cp932' end, {})

-- Appoint
vim.api.nvim_create_user_command('WUnix',[[write<bang> ++fileformat=unix <args> | edit <args>]],{nargs='?', complete='file', bang=true})
vim.api.nvim_create_user_command('WDos',[[write<bang> ++fileformat=dos <args> | edit <args>]],{nargs='?', complete='file', bang=true})

