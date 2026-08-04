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

  -- nvim 0.13+: `vim.lsp.config` is a resolved metatable table (merges
  -- runtime lsp/<name>.lua files and registered configs). `vim.lsp.configs`
  -- was removed; keep it as a fallback for older versions.
  if vim.lsp.config then
    local ok2, resolved = pcall(function()
      return vim.lsp.config[name]
    end)
    if ok2 and resolved then
      return resolved
    end
  end

  return vim.lsp.configs and vim.lsp.configs[name]
end

---@param name string
---@return string[]?
local function server_languages(name)
  local config = get_vim_lsp_config(name)
  local filetypes = config and config.filetypes
  local kakehashi_config = require('vimrc.kakehashi_config')
  local kakehashi_filetypes = kakehashi_config.server_filetypes[name]
  if kakehashi_filetypes then
    -- server_filetypes doubles as an EXTENSION, not only a fallback:
    -- filetypes listed here but absent from the nvim LSP config still get
    -- bridged (e.g. dpp -> emmylua_ls, see kakehashi_config.lua).
    local merged = vim.list_extend({}, filetypes or {})
    for _, ft in ipairs(kakehashi_filetypes) do
      if not vim.tbl_contains(merged, ft) then
        merged[#merged + 1] = ft
      end
    end
    return merged
  end
  return filetypes
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

--- Re-pull diagnostics once kakehashi's settings reload has landed.
---
--- The initial textDocument/diagnostic pull (nvim fires it right after
--- LspAttach) races with the didChangeConfiguration above, so it returns
--- "no host-capable server" and nvim never re-pulls on its own. Poll
--- effectiveConfiguration until the pushed servers are visible, then
--- re-request per attached buffer through the default handler so the
--- response lands in vim.diagnostic (result_id tracking stays intact).
---@param client vim.lsp.Client
---@param expected_servers table<string, any>
---@param attempts number
local function refresh_diagnostics_after_config(client, expected_servers, attempts)
  client:request('kakehashi/internal/effectiveConfiguration', vim.empty_dict(), function(err, result)
    if err or not result then
      return
    end

    local settings = kakehashi_settings(result)
    local servers = settings.languageServers or {}
    for name in pairs(expected_servers) do
      if not servers[name] and attempts > 0 then
        vim.defer_fn(function()
          refresh_diagnostics_after_config(client, expected_servers, attempts - 1)
        end, 300)
        return
      end
    end

    -- Let the initial on_attach pull settle first, so the dedupe check below
    -- sees its outcome (it races the config reload, so it may answer 0 or
    -- items depending on timing).
    vim.defer_fn(function()
      local buffers = vim.tbl_keys(client.attached_buffers or {})
      for _, bufnr in ipairs(buffers) do
        -- Skip buffers the initial pull already served (prevents duplicates;
        -- a clean file with 0 diagnostics re-pulls harmlessly into 0).
        if #vim.diagnostic.get(bufnr) == 0 then
          client:request('textDocument/diagnostic', {
            textDocument = { uri = vim.uri_from_bufnr(bufnr) },
          }, nil, bufnr)
        end
      end
    end, 1500)
  end)
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

    -- The initial pull races with the settings reload (see helper).
    refresh_diagnostics_after_config(client, configured_servers, 10)
  end)
end

return M
