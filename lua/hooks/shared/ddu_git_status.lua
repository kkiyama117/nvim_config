-- Shared function for ddu-source-git_status
-- Used by both `;gs` (ddu.vim.lua) and `[GIT]s` (vim-gin.lua)
local M = {}

function M.start()
  vim.fn['ddu#start']({
    name = 'git_status',
    sources = {
      {
        name = 'git_status',
      },
    },
    sourceOptions = {
      git_status = {
        defaultAction = 'open',
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
