local M = {}
local vimx = require 'artemis'

M.setup = function()
  vim.g["denops#debug"] = true
  -- allow-all, unstable-kv, quiet
  vim.g["denops#server#deno_args"] = {'-q', '-A', '--unstable-kv'}

	-- Restart Denops server
  vim.api.nvim_create_user_command('DenopsRestart', function() vim.fn["denops#server#restart"]() end, {})

	-- Fix Deno module cache issue
  vim.api.nvim_create_user_command('DenopsFixCache', function() vim.fn["denops#cache#update"]({reload = true}) end, {})
end

return M

