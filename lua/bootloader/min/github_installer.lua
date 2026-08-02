--- Git-based plugin installer for the minimum bootloader.
---
--- Clones repositories with a partial clone (`--filter blob:none`) into
--- the dpp GitHub cache layout.
local M = {}
local is_debug = vim.g['vimrc#is_debug']

--- Clone a remote Git repository into the dpp plugin cache.
---
--- Uses `git clone --filter blob:none` for a shallow blob-less checkout.
---@param args {repo: string, dest: string} `repo`: clone URL; `dest`: target directory
---@return boolean `true` when clone succeeded
local function install_from_remote(args)
  if is_debug then
    vim.notify('[VIMRC#BOOTLOADER]: install_from_remote', vim.log.levels.DEBUG)
    vim.notify(
      '[VIMRC#BOOTLOADER]: args=' .. vim.inspect(args),
      vim.log.levels.DEBUG
    )
  end
  local git_clone_log = vim.fn.system({
    'git',
    'clone',
    '--filter',
    'blob:none',
    args.repo,
    args.dest,
  })
  if is_debug then
    vim.notify(
      ('[VIMRC#BOOTLOADER]: log=%s'):format(git_clone_log),
      vim.log.levels.TRACE
    )
  end
  if vim.v.shell_error ~= 0 then
    vim.notify(
      ('[VIMRC#BOOTLOADER]: failed to clone %s'):format(args.repo),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

---@type fun(args: {repo: string, dest: string}): boolean
M.install_from_remote = install_from_remote
return M

