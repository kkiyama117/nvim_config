-- CWD-based git status.
-- Ported from kyoh86/dotfiles (nvim/lua/kyoh86/plug/heirline/git.lua).
-- Improvements over the original:
--   * `git status` runs asynchronously (the original blocks on `:wait()`
--     inside the statusline `condition`, i.e. on every statusline eval)
--   * the result is cached and only refreshed on triggers (index fs_event,
--     file writes, DirChanged, 5s fallback timer)
--   * `.git` files (worktrees/submodules) are resolved to the real gitdir
--
-- NOTE: keep the definition order in mind. Lua closures capture locals only
-- when the local is already in scope at the point of the closure's
-- compilation; a reference to a `local` declared later silently becomes a
-- global access (nil at runtime). Pure helpers come first, and the mutually
-- recursive refresh/start_watching/debounced_refresh chain uses forward
-- declarations.

local stat = {
  has_git = false,
  branch = nil,
  remote = nil,
  ahead = 0,
  behind = 0,
  unmerged = 0,
  untracked = 0,
  staged = 0,
  unstaged = 0,
  dirty = false,
}

local watch_handler = assert(vim.uv.new_fs_event())
local timer_handler = assert(vim.uv.new_timer())
local debounce_timer = assert(vim.uv.new_timer())
local gitdir = ""
local running = false
local pending = false

local function notify_update()
  vim.api.nvim_exec_autocmds("User", { pattern = "UpdateHeirlineGitStatus" })
  vim.cmd("redrawstatus")
end

--- Split a line which holds branch status from git-status-porcelain
--- The line holds a local branch name, remote, ahead and behind commit counts like below.
---     ## main...origin/main [ahead 3, behind 2]
--- Each word can be dropped if it has no significant value like below.
---     ## main...origin/main [behind 9]
---     ## feature-1
--- This function returns branch, remote, ahead and behind for each.
---@param line string A line of the branch in git-status-porcelain
---@return string, string|nil, number, number
local function split_branch_line(line)
  local words = vim.fn.split(line, "\\.\\.\\.\\|[ \\[\\],]")
  if #words == 2 then
    return words[2], nil, 0, 0
  elseif #words > 3 then
    local info = {}
    local key = ""
    for i, r in ipairs(words) do
      if i > 3 then
        if key ~= "" then
          info[key] = r
          key = ""
        else
          key = r
        end
      end
    end
    return words[2], words[3], info["ahead"], info["behind"]
  else
    return words[2], words[3], 0, 0
  end
end

local function signif(x)
  if x == nil then
    return false
  elseif type(x) == "number" then
    return x ~= 0
  elseif type(x) == "string" then
    local n = tonumber(x)
    if n == nil then
      return x ~= ""
    end
    return n ~= 0
  end
end

local ERROR_NOT_GIT_REPOSITORY = "fatal: not a git repository"
local ERROR_NOT_GIT_WORKTREE = "fatal: this operation must be run in a work tree"

local function parse_status(completed)
  local info = {
    has_git = false, branch = nil, remote = nil,
    ahead = 0, behind = 0, unmerged = 0, untracked = 0,
    staged = 0, unstaged = 0, dirty = false,
  }
  if completed.code ~= 0 then
    if string.sub(completed.stderr, 1, string.len(ERROR_NOT_GIT_REPOSITORY)) == ERROR_NOT_GIT_REPOSITORY then
      return info
    end
    if string.sub(completed.stderr, 1, string.len(ERROR_NOT_GIT_WORKTREE)) == ERROR_NOT_GIT_WORKTREE then
      return info
    end
    vim.notify("failed to call git-status (code: " .. completed.code .. ") " .. completed.stderr, vim.log.levels.WARN)
    return info
  end
  for _, file in ipairs(vim.fn.split(completed.stdout, "\n")) do
    local staged = string.sub(file, 1, 1)
    local unstaged = string.sub(file, 2, 2)
    local changed = string.sub(file, 1, 2)
    if changed == "##" then
      -- ブランチ名を取得する
      info.branch, info.remote, info.ahead, info.behind = split_branch_line(file)
      info.dirty = info.dirty or signif(info.ahead) or signif(info.behind)
      info.has_git = info.branch ~= ""
    elseif staged == "U" or unstaged == "U" or changed == "AA" or changed == "DD" then
      info.unmerged = info.unmerged + 1
      info.dirty = true
    elseif changed == "??" then
      info.untracked = info.untracked + 1
      info.dirty = true
    else
      if staged ~= " " then
        info.staged = info.staged + 1
        info.dirty = true
      end
      if unstaged ~= " " then
        info.unstaged = info.unstaged + 1
        info.dirty = true
      end
    end
  end
  return info
end

-- forward declarations (refresh <-> start_watching/debounced_refresh cycle)
local refresh
local debounced_refresh

local function start_timer()
  timer_handler:start(5000, 5000, vim.schedule_wrap(refresh))
end

local function stop_timer()
  timer_handler:stop()
end

local function start_watching()
  if gitdir == "" or vim.fn.filereadable(gitdir .. "/index") == 0 then
    return
  end
  vim.uv.fs_event_start(
    watch_handler,
    gitdir .. "/index",
    {},
    vim.schedule_wrap(function(err)
      if err then
        vim.notify("failed to watch git-path: " .. err, vim.log.levels.WARN)
        return
      end
      debounced_refresh()
    end)
  )
end

local function stop_watching()
  watch_handler:stop()
end

-- Resolve the real gitdir of `path` (handles `.git` files of worktrees/submodules)
local function resolve_gitdir(path)
  local dotgit = path .. "/.git"
  if vim.fn.isdirectory(dotgit) == 1 then
    return dotgit
  end
  local f = io.open(dotgit, "r")
  if not f then
    return nil
  end
  local line = f:read("*l")
  f:close()
  if line and vim.startswith(line, "gitdir:") then
    local dir = vim.trim(line:sub(8))
    if not vim.startswith(dir, "/") then
      dir = path .. "/" .. dir
    end
    return vim.fn.fnamemodify(dir, ":p")
  end
  return nil
end

refresh = function()
  if running then
    pending = true
    return
  end
  local cwd = vim.fn.getcwd()
  local dir = resolve_gitdir(cwd)
  if not dir then
    gitdir = ""
    stat = {
      has_git = false, branch = nil, remote = nil,
      ahead = 0, behind = 0, unmerged = 0, untracked = 0,
      staged = 0, unstaged = 0, dirty = false,
    }
    notify_update()
    return
  end
  gitdir = dir
  running = true
  stop_watching() -- `git status` refreshes the index; avoid self-triggering
  vim.system(
    { "git", "--no-optional-locks", "status", "--porcelain", "--branch", "--ahead-behind", "--untracked-files", "--renames" },
    { cwd = cwd, text = true },
    function(completed)
      -- on_exit runs in a fast event context where Vimscript functions
      -- (vim.fn.*) are forbidden (E5560); defer to the main loop.
      vim.schedule(function()
        running = false
        stat = parse_status(completed)
        start_watching()
        notify_update()
        if pending then
          pending = false
          refresh()
        end
      end)
    end
  )
end

debounced_refresh = function()
  debounce_timer:start(500, 0, vim.schedule_wrap(refresh))
end

local group = vim.api.nvim_create_augroup("hooks_heirline_git", { clear = true })

vim.api.nvim_create_autocmd("DirChangedPre", {
  group = group,
  pattern = "global",
  callback = stop_watching,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  pattern = "global",
  callback = refresh,
})

vim.api.nvim_create_autocmd({ "FileChangedShellPost", "FileWritePost", "BufWritePost", "TermLeave" }, {
  group = group,
  callback = debounced_refresh,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = stop_timer,
})

start_timer()
vim.schedule(refresh)

-- --------------------------------------------------------------------------
-- component
-- --------------------------------------------------------------------------

local Padding = { provider = " " }

local LocalBranch = {
  provider = function()
    if stat.branch ~= nil then
      return "\u{F418}" .. stat.branch -- 
    end
  end,
  hl = { fg = "orange", bold = true },
}

local RemoteBranch = {
  provider = function()
    if stat.remote ~= nil then
      return " \u{F427}" .. stat.remote -- 
    else
      return " \u{F0674} " -- 󰙴 (no upstream)
    end
  end,
  hl = { fg = "gray" },
}

local function numeric_stat_module(prefix, key)
  return {
    provider = function()
      local s = stat[key]
      if signif(s) then
        return prefix .. s
      end
    end,
  }
end

local StatAhead = numeric_stat_module("\u{EAA1}", "ahead") -- 
local StatBehind = numeric_stat_module("\u{EA9A}", "behind") -- 
local StatUnmerged = numeric_stat_module("\u{F06C4} ", "unmerged") -- 󰛄
local StatStaged = numeric_stat_module("\u{F012C} ", "staged") -- 󰄬
local StatUnstaged = numeric_stat_module("\u{F0415} ", "unstaged") -- 󰐕
local StatUntracked = numeric_stat_module(" \u{F0205} ", "untracked") -- 󰈅

local Git = {
  {
    {
      -- Git branch
      Padding,
      LocalBranch,
      RemoteBranch,
    },
    Padding,
    {
      -- Git status
      StatAhead,
      StatBehind,
      StatUnmerged,
      StatStaged,
      StatUnstaged,
      StatUntracked,
      Padding,

      hl = { fg = "black", bg = "diag_warn", bold = true },
      condition = function()
        return stat.dirty
      end,
    },
    condition = function()
      return stat.has_git
    end,
  },
  update = {
    "User",
    pattern = "UpdateHeirlineGitStatus",
  },
}

return Git
