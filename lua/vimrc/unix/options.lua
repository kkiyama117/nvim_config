-- For UNIX
vim.opt.shell = 'zsh'

-- Set path.
--vim.env.PATH = vim.fn.expand('~/.local/bin/') .. ':/usr/local/bin/:' .. vim.env.PATH

if vim.fn.has('gui_running') == 0 then
  -- Disable the mouse.
  vim.opt.mouse = ''
end

