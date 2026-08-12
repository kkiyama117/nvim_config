-- Debug-mode logging.
--
-- Saves nvim logs to `$NVIM_CACHE_HOME/logs` when debug mode is enabled
-- (`vim.g['vimrc#is_debug']`, set from `NVIM_DEBUG=true` in init.lua).
--
-- Sourced via rvpm loader; guards itself and
-- no-ops in normal mode.

if not vim.g['vimrc#is_debug'] then
  return
end

local log_dir = vim.fs.joinpath(vim.env.NVIM_CACHE_HOME, 'logs')
vim.fn.mkdir(log_dir, 'p')

-- 1. Verbose log: sourced files, autocmds, option changes, ...
vim.o.verbose = 3
vim.o.verbosefile = vim.fs.joinpath(log_dir, 'verbose.log')

-- 2. Tee `vim.notify` to a file (nvim-notify swallows messages otherwise).
--    The nvim-notify hook re-wraps after
--    `vim.notify = plugin` replaces this early wrapper.
vim.notify = require('vimrc.utils').wrap_notify_with_log(log_dir)

-- 3. Dump `:messages` (denops echomsg, etc.) on exit.
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = vim.g['vimrc#augroup'],
  callback = function()
    local messages = vim.fn.execute('messages')
    if messages ~= '' then
      vim.fn.writefile(
        vim.split(messages, '\n'),
        vim.fs.joinpath(log_dir, 'messages.log')
      )
    end
  end,
})

vim.notify('[VIMRC]: DEBUG MODE ENABLED', vim.log.levels.DEBUG)
