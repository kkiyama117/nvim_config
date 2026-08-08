local M = {}

local function ddu_git_branch()
  vim.fn['ddu#start']({
    name = 'git_branch',
    sources = {
      {
        name = 'git_branch',
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

-- `ddu-source-git_log` has own `action` (ddu-kind)
-- TODO: add `buffer's log`
local function ddu_git_log()
  vim.fn['ddu#start']({
    name = 'git_log',
    sources = {
      {
        name = 'git_log',
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

-- `ddu-source-git_stash` has own `action` (ddu-kind)
local function ddu_git_stash()
  vim.fn['ddu#start']({
    name = 'git_stash',
    sources = {
      {
        name = 'git_stash',
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

-- `ddu-source-git_status` has own `action` (ddu-kind, converter)
local function ddu_git_status()
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

M.ddu_git_branch = ddu_git_branch
M.ddu_git_log = ddu_git_log
M.ddu_git_stash = ddu_git_stash
M.ddu_git_status = ddu_git_status

return M

