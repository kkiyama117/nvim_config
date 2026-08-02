local M = {}
local is_debug = vim.g['vimrc#is_debug'] == 'true'

-- ==========================================================================
-- Safe dpp installer
-- ==========================================================================
-- TODO: use `getFailed` of dpp and autofix broken plugins
-- ==========================================================================

---When config_files are updated, do everythings written below
---
---  1: install plugins if not installed
---  2: update plugins if needed
---  3: call dpp#make_state (bootloader/dpp/make_state.lua)
---@param args { cache_home: string,cache_github:string, dpp_script: string}
local function hooks_config_files_updated(args)
  -- 1: check all plugins are installed
  if #vim.fn['dpp#sync_ext_action']('installer', 'getNotInstalled') > 0 then
    -- 1-A: if exists, then install and make AutoCmd to hook `2`
    vim.fn['dpp#async_ext_action']('installer', 'install')
    vim.api.nvim_create_autocmd('User', {
      pattern = 'Dpp:ext:installer:updateDone',
      group = vim.g['vimrc#augroup'],
      once = true,
      callback = function()
        -- call `2`
        vim.fn['dpp#async_ext_action']('installer', 'checkNotUpdated')
      end,
    })
  else
    -- 1-B: if `1` is skipped, do `2` directly.
    vim.fn['dpp#async_ext_action']('installer', 'checkNotUpdated')
  end
  -- 2: AutoCmd that wait `checkNotUpdated` and then do `3`
  -- Even if no plugins are updated, this should cbe called
  vim.api.nvim_create_autocmd('User', {
    pattern = 'Dpp:ext:installer:updateDone',
    group = vim.g['vimrc#augroup'],
    once = true,
    callback = function()
      -- 3: then call dpp#make_state to save new state
      require('bootloader/dpp/make_state').run({
        cache_home = args.cache_home,
        cache_github = args.cache_github,
        dpp_script = args.dpp_script,
      })
    end,
  })
end

---@param args { cache_home: string,cache_github:string, dpp_script: string}
---@param force boolean if true, force update
local function dpp_update(args, force)
  local updated_files = vim.fn['dpp#check_files'](args.cache_home)
  if
    (type(updated_files) == 'table' and not vim.tbl_isempty(updated_files))
    or force
  then
    vim.notify('[VIMRC#BOOTLOADER#dpp]: Update started', vim.log.levels.WARN)
    -- Mark in-flight so VimLeavePre can wait for completion.
    -- Cleared by the Dpp:makeStatePost autocmd below.
    vim.g['vimrc#bootloader#under_dpp_updating'] = true
    hooks_config_files_updated(args)
  else
    vim.notify(
      '[VIMRC#BOOTLOADER#dpp]: No config files are updated',
      vim.log.levels.INFO
    )
  end
end

M.dpp_update = dpp_update
M.dpp_update_force = function(args)
  dpp_update(args, true)
end
return M

