-- lua_source {{{
local bridge = require('vimrc.kakehashi_bridge')
local config = require('vimrc.kakehashi_config')

local function kakehashi_plugin_path()
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if path:find('kakehashi%.nvim') then
      return path
    end
  end
end

local home = vim.env.HOME or '~'
local data_path = vim.fs.joinpath(home, '.local', 'share', 'kakehashi')

-- Repo-owned kakehashi assets (queries, future parsers):
-- $NVIM_CONFIG_HOME/kakehashi/queries/<lang>/...
local config_home = vim.env.NVIM_CONFIG_HOME or vim.fn.stdpath('config')
local kakehashi_asset_path = vim.fs.joinpath(config_home, 'kakehashi')

local init_options = {
  autoInstall = true,
  searchPaths = vim.tbl_filter(function(path)
    return path ~= nil and path ~= ''
  end, {
    data_path,
    kakehashi_asset_path,
    kakehashi_plugin_path(),
  }),
  languages = config.languages(),
}

vim.lsp.config('kakehashi', {
  cmd = { 'kakehashi' },
  filetypes = config.filetypes(),
  init_options = init_options,
  on_init = function(client)
    -- Prefer semanticTokens/full/delta over range requests.
    local provider = client.server_capabilities.semanticTokensProvider
    if provider then
      provider.range = false
    end
  end,
})

-- kakehashi is the sole Neovim LSP client; bridged servers run as children.
vim.lsp.enable('kakehashi')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == 'kakehashi' then
      bridge.inherit(client, config.bridged_servers, 'keep')

      -- Let kakehashi own highlighting once semantic tokens arrive
      -- (scripts/minimal_init.lua, kakehashi README Quick Start).
      vim.api.nvim_create_autocmd('LspTokenUpdate', {
        buffer = ev.buf,
        once = true,
        callback = function()
          vim.opt_local.syntax = 'OFF'
          vim.treesitter.stop(ev.buf)
        end,
      })
    end
  end,
})
-- }}}
