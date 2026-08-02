--- Minimum bootloader for rescue installs without dpp/denops.
---
--- Used during fallback (F2/F3) or on a fresh Neovim session that cannot
--- load `dpp.vim` or `denops.vim`. Clones missing plugins from GitHub via
--- `bootloader/min/github_installer` and optionally restarts Neovim.
local M = {}
local is_debug = vim.g['vimrc#is_debug']

local m_github_installer = require('bootloader/min/github_installer')

--- Clone missing plugins from GitHub into the dpp cache.
---
--- Skips repos already present on disk. Verifies every plugin exists after
--- cloning before returning success.
---@param missing_plugins string[] Repository names (e.g. `"Shougo/dpp.vim"`)
---@return boolean `true` when all plugins are installed
local function rescue(missing_plugins)
  -- 1: install missing_plugins
  local cache_github = vim.fs.joinpath(
    vim.fs.joinpath(vim.env.NVIM_CACHE_HOME, 'dpp'),
    'repos',
    'github.com'
  )
  for _, repo in ipairs(missing_plugins) do
    local dest = vim.fs.joinpath(cache_github, repo)
    local stat = vim.uv.fs_stat(dest)
    if stat and stat.type == 'directory' then
      if is_debug then
        vim.notify(
          ('[VIMRC#BOOTLOADER]: already installed: %s'):format(repo),
          vim.log.levels.DEBUG
        )
      end
    else
      local ok = m_github_installer.install_from_remote({
        repo = ('https://github.com/%s'):format(repo),
        dest = dest,
      })
      if not ok then
        vim.notify(
          ('[VIMRC#BOOTLOADER]: failed to install %s'):format(repo),
          vim.log.levels.ERROR
        )
        return false
      end
    end
  end
  -- 2: check they are installed
  for _, repo in ipairs(missing_plugins) do
    local dest = vim.fs.joinpath(cache_github, repo)
    local stat = vim.uv.fs_stat(dest)
    if not stat or stat.type ~= 'directory' then
      vim.notify(
        ('[VIMRC#BOOTLOADER]: %s still missing after install'):format(repo),
        vim.log.levels.ERROR
      )
      return false
    end
  end
  return true
end

--- Install minimum deps and restart Neovim (F2 fallback).
---
--- Used when `dpp#min#load_state` is unavailable. After a successful
--- clone, runs `:restart!` so the new plugins can be loaded.
---@param missing_plugins string[] Repository names to install
---@return boolean `false` when clone failed; otherwise restarts and does not return
M.rescue_min = function(missing_plugins)
  local ok = rescue(missing_plugins)
  if not ok then
    return false
  end
  -- 3: restart to load the newly installed plugins
  -- TODO: add asking users to restart or not
  vim.notify(
    '[VIMRC#BOOTLOADER]: minimum deps installed, restarting...',
    vim.log.levels.INFO
  )
  vim.cmd('restart!')
  return true
end

--- Install normal dpp deps without restarting (F3 fallback).
---
--- Same clone logic as `rescue_min`, but leaves Neovim running so the caller
--- can retry `make_state` after plugins are on disk.
---@param missing_plugins string[] Repository names to install
---@return boolean `true` when all plugins were cloned successfully
M.rescue_normal = function(missing_plugins)
  return rescue(missing_plugins)
end

return M

