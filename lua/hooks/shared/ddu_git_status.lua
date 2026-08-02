-- Shared function for ddu-source-git_status
-- Used by both `;gs` (ddu.vim.lua) and `[GIT]s` (vim-gin.lua)
local M = {}

function M.start()
  if vim.fn.exists('*ddu#start') == 0 then
    vim.notify('ddu.vim is not loaded', vim.log.levels.WARN)
    return
  end
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
