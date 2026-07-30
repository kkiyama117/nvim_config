-- lua_add {{{
-- ==========================================================================
-- Install missing plugins and update plugins with upstream changes.

-- NOTE: getNotUpdated contacts the remote (git ls-remote / GitHub API), so the
-- sync call blocks Neovim for a moment.  That is acceptable for a manual
-- command but keep it out of startup-critical paths.
-- ==========================================================================
local dpp_installer = require('dpp_installer')

local function dpp_ensure_ready()
  if not (vim.g.dpp and vim.g.dpp.settings and vim.g.dpp.settings.base_path) then
    vim.notify('dpp is not initialized', vim.log.levels.ERROR)
    return false
  end
  if not vim.g.loaded_denops then
    vim.notify('denops is not ready yet; retry after DenopsReady', vim.log.levels.ERROR)
    return false
  end
  return true
end

local function names_of(plugins)
  return vim.tbl_map(function(p)
    return p.name
  end, plugins)
end

local function complete_plugins()
  local plugins = (vim.g.dpp and vim.g.dpp.state or {}).plugins or {}
  return vim.tbl_keys(plugins)
end

local function dpp_install(opts)
  if not dpp_ensure_ready() then
    return
  end

  local names = (opts and opts.fargs) or {}
  local install_names, reinstall_names = dpp_installer.collect_targets(names)
  if not dpp_installer.apply(install_names, reinstall_names) then
    vim.notify('[dpp] no missing or broken plugins', vim.log.levels.INFO)
  end
end

local function dpp_install_update(opts)
  if not dpp_ensure_ready() then
    return
  end

  local names = (opts and opts.fargs) or {}

  dpp_install(opts)

  local not_updated = vim.fn['dpp#sync_ext_action']('installer', 'getNotUpdated', { names = names })
  if type(not_updated) == 'table' and not vim.tbl_isempty(not_updated) then
    local list = names_of(not_updated)
    vim.notify(('[dpp] updating %d: %s'):format(#list, table.concat(list, ', ')), vim.log.levels.INFO)
    vim.fn['dpp#async_ext_action']('installer', 'update', { names = list })
  else
    vim.notify('[dpp] no updates available', vim.log.levels.INFO)
  end
end
-- ==========================================================================
vim.api.nvim_create_user_command('DppInstall', dpp_install, {
  desc = 'Install missing plugins only (no remote update check)',
  nargs = '*',
  complete = complete_plugins,
})
vim.api.nvim_create_user_command('DppInstallUpdate', dpp_install_update, {
  desc = 'Install missing plugins and update plugins with upstream changes',
  nargs = '*',
  complete = complete_plugins,
})
-- }}}

