--- Bridge Neovim LSP configs into kakehashi's languageServers.
---
--- Like `kakehashi.inherit_nvim_lsp_config`, but resolves executable paths via
--- `vim.fn.exepath()` so Mason-installed binaries work when kakehashi spawns
--- downstream servers as child processes.
local M = {}

local IGNORED = { copilot = true, kakehashi = true }

---@param result table?
---@return table
local function kakehashi_settings(result)
  local settings = result and result.settings or {}
  -- kakehashi 0.9+ expects runtime settings under settings.kakehashi.
  return settings.kakehashi or settings
end

---@param name string
---@return vim.lsp.Config?
local function get_vim_lsp_config(name)
  local ok, config = pcall(function()
    return vim.lsp._enabled_configs[name].resolved_config
  end)
  if ok and config then
    return config
  end

  return vim.lsp.configs and vim.lsp.configs[name]
end

---@param name string
---@return string[]?
local function server_languages(name)
  local config = get_vim_lsp_config(name)
  if config and config.filetypes then
    return config.filetypes
  end
  local kakehashi_config = require('vimrc.kakehashi_config')
  return kakehashi_config.server_filetypes[name]
end

---@param cmd string[]
---@return string[]?
local function resolve_cmd(cmd)
  if type(cmd) ~= 'table' or cmd[1] == nil then
    return nil
  end

  local bin = cmd[1]
  local path = vim.fn.exepath(bin)
  if path ~= '' then
    bin = path
  end

  local resolved = { bin }
  for i = 2, #cmd do
    resolved[i] = cmd[i]
  end
  return resolved
end

---@param client vim.lsp.Client
---@param servers string[]
---@param behavior? "error" | "keep" | "force"
function M.inherit(client, servers, behavior)
  behavior = behavior or 'keep'

  ---@diagnostic disable-next-line: param-type-mismatch
  client:request('kakehashi/internal/effectiveConfiguration', vim.empty_dict(), function(err, result)
    if err then
      vim.notify('[kakehashi bridge] ' .. tostring(err), vim.log.levels.ERROR)
      return
    end

    local settings = kakehashi_settings(result)
    local configured_servers = settings.languageServers or {}

    for _, name in ipairs(servers) do
      if not IGNORED[name] then
        local config = get_vim_lsp_config(name)
        local cmd = config and type(config.cmd) == 'table' and resolve_cmd(config.cmd) or nil
        local languages = server_languages(name)
        if cmd and languages then
          local bridge_config = {
            cmd = cmd,
            languages = languages,
            workspaceMarkers = config and config.root_markers,
          }
          if config and config.settings then
            bridge_config.settings = config.settings
          end
          if config and config.init_options then
            bridge_config.initializationOptions = config.init_options
          end
          configured_servers[name] = vim.tbl_extend(behavior, configured_servers[name] or {}, bridge_config)
        end
      end
    end

    client:notify('workspace/didChangeConfiguration', {
      settings = {
        kakehashi = {
          languageServers = configured_servers,
        },
      },
    })
  end)
end

return M
