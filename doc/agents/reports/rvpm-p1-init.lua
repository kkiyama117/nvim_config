vim.loader.enable()
if vim.fn.executable("deno") == 0 then
  local mise_deno = vim.fs.joinpath(vim.env.HOME, ".local/share/mise/installs/deno/latest/bin/deno")
  if vim.fn.executable(mise_deno) == 1 then
    vim.g["denops#deno"] = mise_deno
  end
end
local loader = vim.fn.expand("~/.cache/rvpm/nvim-rvpm/plugins/loader.lua")
if vim.uv.fs_stat(loader) then dofile(loader) end
