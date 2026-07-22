-- Reopen with specific encoding
vim.api.nvim_create_user_command('Utf8', function(opts)
  vim.cmd('edit' .. (opts.bang and '!' or '') .. ' ++enc=utf-8 ' .. opts.args)
end, { bang = true, bar = true, complete = 'file', nargs = '?' })

vim.api.nvim_create_user_command('Iso2022jp', function(opts)
  vim.cmd('edit' .. (opts.bang and '!' or '') .. ' ++enc=iso-2022-jp ' .. opts.args)
end, { bang = true, bar = true, complete = 'file', nargs = '?' })

vim.api.nvim_create_user_command('Cp932', function(opts)
  vim.cmd('edit' .. (opts.bang and '!' or '') .. ' ++enc=cp932 ' .. opts.args)
end, { bang = true, bar = true, complete = 'file', nargs = '?' })

vim.api.nvim_create_user_command('Euc', function(opts)
  vim.cmd('edit' .. (opts.bang and '!' or '') .. ' ++enc=euc-jp ' .. opts.args)
end, { bang = true, bar = true, complete = 'file', nargs = '?' })

-- Set local file encoding only
vim.api.nvim_create_user_command('WUtf8', function()
  vim.bo.fileencoding = 'utf-8'
end, {})

vim.api.nvim_create_user_command('WCp932', function()
  vim.bo.fileencoding = 'cp932'
end, {})

-- Write with specific line feed format, then reload
vim.api.nvim_create_user_command('WUnix', function(opts)
  vim.cmd('write' .. (opts.bang and '!' or '') .. ' ++fileformat=unix ' .. opts.args)
  vim.cmd('edit ' .. opts.args)
end, { bang = true, complete = 'file', nargs = '?' })

vim.api.nvim_create_user_command('WDos', function(opts)
  vim.cmd('write' .. (opts.bang and '!' or '') .. ' ++fileformat=dos ' .. opts.args)
  vim.cmd('edit ' .. opts.args)
end, { bang = true, complete = 'file', nargs = '?' })

