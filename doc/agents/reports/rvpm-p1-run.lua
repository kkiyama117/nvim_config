vim.loader.enable()
if vim.fn.executable("deno") == 0 then
  local mise_deno = vim.fs.joinpath(vim.env.HOME, ".local/share/mise/installs/deno/latest/bin/deno")
  if vim.fn.executable(mise_deno) == 1 then
    vim.g["denops#deno"] = mise_deno
  end
end
local loader = vim.fn.expand("~/.cache/rvpm/nvim-rvpm/plugins/loader.lua")
if vim.uv.fs_stat(loader) then dofile(loader) end

vim.wait(30000, function() return vim.fn["denops#server#status"]() == "running" end, 50)

vim.cmd("enew")
print("pre skel", _G.rvpm_loaded_skkeleton, vim.fn["denops#plugin#is_loaded"]("skkeleton"))
vim.cmd("call feedkeys(\"\\<C-j>\", 'nx')")
vim.wait(10000, function()
  return _G.rvpm_loaded_skkeleton == true and vim.fn["denops#plugin#is_loaded"]("skkeleton") == 1
end, 50)
print("post skel", _G.rvpm_loaded_skkeleton, vim.fn["denops#plugin#is_loaded"]("skkeleton"))

print("pre ddu", _G.rvpm_loaded_ddu_vim, vim.fn["denops#plugin#is_loaded"]("ddu"))
pcall(vim.cmd, "Ddu")
vim.wait(10000, function()
  return _G.rvpm_loaded_ddu_vim == true and vim.fn["denops#plugin#is_loaded"]("ddu") == 1
end, 50)
print("post ddu", _G.rvpm_loaded_ddu_vim, vim.fn["denops#plugin#is_loaded"]("ddu"))

print("pre ddc", _G.rvpm_loaded_ddc_vim, vim.fn["denops#plugin#is_loaded"]("ddc"))
vim.cmd("enew")
vim.cmd("startinsert")
vim.wait(10000, function()
  return _G.rvpm_loaded_ddc_vim == true and vim.fn["denops#plugin#is_loaded"]("ddc") == 1
end, 50)
print("post ddc", _G.rvpm_loaded_ddc_vim, vim.fn["denops#plugin#is_loaded"]("ddc"))

vim.cmd("qa!")
