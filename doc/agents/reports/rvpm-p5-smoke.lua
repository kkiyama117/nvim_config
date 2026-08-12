-- P5 denops smoke test (uses init.lua loader)
vim.wait(30000, function()
  return vim.fn.exists("*denops#server#status") == 1
    and vim.fn["denops#server#status"]() == "running"
end, 50)

print("denops_status", vim.fn["denops#server#status"]())

print(
  "skel",
  _G.rvpm_loaded_skkeleton,
  vim.fn["denops#plugin#is_loaded"]("skkeleton")
)

vim.api.nvim_exec_autocmds("User", { pattern = "DenopsReady", modeline = false })
vim.wait(10000, function()
  return _G.rvpm_loaded_ddu_vim == true and vim.fn["denops#plugin#is_loaded"]("ddu") == 1
end, 50)
print("ddu", _G.rvpm_loaded_ddu_vim, vim.fn["denops#plugin#is_loaded"]("ddu"))

vim.cmd("enew")
vim.api.nvim_exec_autocmds("InsertEnter", { modeline = false })
vim.wait(10000, function()
  return _G.rvpm_loaded_ddc_vim == true and vim.fn["denops#plugin#is_loaded"]("ddc") == 1
end, 50)
print("ddc", _G.rvpm_loaded_ddc_vim, vim.fn["denops#plugin#is_loaded"]("ddc"))

print("overseer_lazy", _G.rvpm_loaded_overseer_nvim)
print("notify_eager", _G.rvpm_loaded_nvim_notify)
