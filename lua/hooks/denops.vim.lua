-- lua_source {{{
local deno_args_list = {
  '-q',
  '-A',
  '--unstable-kv', -- for Deno KV storage
  '--unstable-ffi', -- for deno-pty-ffi (https://github.com/sigmaSd/deno-pty-ffi)
  -- vim.g.denops_server_addr = '127.0.0.1:32123'
}
if vim.env.NVIM_DEBUG == 'true' then
  vim.g['denops#debug'] = true
  table.insert(deno_args_list, '--inspect')
end

-- denops.vim's default is ['-q', '--no-lock', '-A'];
vim.g['denops#server#deno_args'] = deno_args_list

-- }}}

