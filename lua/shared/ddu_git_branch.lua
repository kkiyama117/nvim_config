-- Shared function for ddu-source-git_branch
-- Used by both `;gb` (ddu.vim.lua) and `[GIT]b` (vim-gin.lua)
local M = {}

function M.start()
  if vim.fn.exists('*ddu#start') == 0 then
    vim.notify('ddu.vim is not loaded', vim.log.levels.WARN)
    return
  end
  vim.fn['ddu#start']({
    name = 'git_branch',
    sources = {
      {
        name = 'git_branch',
      },
    },
    sourceOptions = {
      register = {
        defaultAction = vim.fn.col('.') == 1 and 'insert' or 'append',
      },
    },
    uiParams = {
      ff = {
        ignoreEmpty = true,
        displayTree = true,
      },
    },
  })
end

return M
