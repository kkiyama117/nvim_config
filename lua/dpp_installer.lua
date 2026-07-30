local M = {}

function M.is_plugin_cache_valid(path)
  if type(path) ~= 'string' or path == '' then
    return false
  end
  path = vim.fs.normalize(path)
  if vim.fn.isdirectory(path) == 0 then
    return false
  end
  local ok, dir = pcall(vim.fs.dir, path)
  if not ok or dir == nil then
    return false
  end
  for entry in dir do
    if entry ~= '.git' then
      return true
    end
  end
  return false
end

function M.iter_plugins(names)
  local state_plugins = (vim.g.dpp and vim.g.dpp.state or {}).plugins or {}
  if type(names) == 'table' and #names > 0 then
    local plugins = {}
    for _, name in ipairs(names) do
      if state_plugins[name] then
        plugins[#plugins + 1] = state_plugins[name]
      end
    end
    return plugins
  end
  return vim.tbl_values(state_plugins)
end

function M.plugin_names(plugins)
  return vim.tbl_map(function(plugin)
    return plugin.name
  end, plugins)
end

function M.get_broken_plugins(names)
  local broken = {}
  for _, plugin in ipairs(M.iter_plugins(names)) do
    local path = plugin.path
    if type(path) == 'string' and path ~= '' and vim.fn.isdirectory(path) ~= 0 then
      if not M.is_plugin_cache_valid(path) then
        broken[#broken + 1] = plugin
      end
    end
  end
  return broken
end

function M.collect_targets(names)
  names = names or {}
  local not_installed = vim.fn['dpp#sync_ext_action']('installer', 'getNotInstalled', { names = names })
  local install_names = type(not_installed) == 'table' and M.plugin_names(not_installed) or {}
  local reinstall_names = M.plugin_names(M.get_broken_plugins(names))
  return install_names, reinstall_names
end

function M.apply(install_names, reinstall_names)
  if #install_names > 0 then
    vim.notify(
      ('[dpp] installing %d: %s'):format(#install_names, table.concat(install_names, ', ')),
      vim.log.levels.INFO
    )
    vim.fn['dpp#async_ext_action']('installer', 'install', { names = install_names })
  end
  if #reinstall_names > 0 then
    vim.notify(
      ('[dpp] reinstalling %d broken cache: %s'):format(#reinstall_names, table.concat(reinstall_names, ', ')),
      vim.log.levels.INFO
    )
    vim.fn['dpp#async_ext_action']('installer', 'reinstall', { names = reinstall_names })
  end
  return #install_names > 0 or #reinstall_names > 0
end

return M
