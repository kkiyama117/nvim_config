-- after/lsp/kakehashi.lua
-- Neovim client config for the kakehashi language server (upstream
-- atusy/kakehashi.nvim), following atusy's dotfiles layout
-- (dot_config/nvim/after/lsp/kakehashi.lua).
--
-- Loaded lazily by `vim.lsp.config['kakehashi']` on first access: nvim
-- resolves `lsp/*.lua` from the runtimepath, and this after/ file is
-- searched last, so it overrides nvim-lspconfig's builtin
-- lsp/kakehashi.lua (later files win in the force-extend merge).
-- `vim.lsp.enable('kakehashi')` is called from
-- lua/hooks/kakehashi.nvim.dpp — NOT here (enable resolves this file,
-- which would recurse).
--
-- Replaces the kkiyama117/kakehashi.nvim fork's plugin/kakehashi.lua
-- (which itself replaced a hooks_file; see fork commit 87d14de). The
-- fork's lua/kakehashi/bridge.lua and lua/kakehashi/config.lua are
-- replaced by:
--   * lua/kakehashi/config.lua (vimrc-owned) — bridged_servers, filetypes,
--     and the `languages` init_options table;
--   * kakehashi-lspconfig TOML fragments + ~/.config/kakehashi/kakehashi.toml
--     (chezmoi-managed; ~/.config/kakehashi also holds the dpp parser,
--     queries, and grammar source) + a generated
--     library.toml, passed to the kakehashi binary via --config-file (the
--     dotfiles model). No inherit_nvim_lsp_config, no didChangeConfiguration:
--     the languageServers are complete at spawn.
--
-- The --config-file model eliminates two fork workarounds by design:
--   * the diagnostics re-pull race (config can no longer arrive late),
--   * the settings.kakehashi wire shape (nothing is pushed at runtime).
-- It also keeps denols bridged (upstream inherit_nvim_lsp_config ignores
-- denols; we don't call it).
--
-- kakehashi is the sole Neovim LSP client; bridged servers (denols,
-- emmylua_ls, gopls, pyright, rust_analyzer, tombi, vtsls) run as its
-- children. Server binaries are installed by mise, NOT mason.nvim.

local config = require('kakehashi.config')

-- ==========================================================================
-- Build the kakehashi --config-file stack
--
-- Files merge in order, later overrides earlier (kakehashi 0.9:
-- --config-file can be specified multiple times; per-server configs are
-- deep-merged, `settings`/`initializationOptions` via deep JSON merge —
-- see src/config/merge.rs):
--   1. lsp.toml      (generated)  kakehashi-lspconfig lsp/*.toml fragments,
--                                 filtered to config.bridged_servers
--   2. kakehashi.toml (repo)      the standard user config at
--                                 ~/.config/kakehashi/kakehashi.toml
--                                 (symlink): enabled = true per bridged
--                                 server + the per-server settings deltas
--                                 the fork used to inherit
--   3. library.toml  (generated)  dynamic emmylua workspace.library from
--                                 the running nvim runtime
-- ==========================================================================

local cache_home = vim.env.NVIM_CACHE_HOME
  or vim.fs.joinpath(vim.env.HOME or '~', '.cache', 'nvim')
local kh_cache = vim.fs.joinpath(cache_home, 'kakehashi')

local function find_plugin_path(pattern)
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if path:match(pattern) then
      return path
    end
  end
end

--- Resolve a fragment `cmd` line's first binary via vim.fn.exepath.
--- Matches the machine-generated single-line form `cmd = ["deno", "lsp"]`;
--- leaves the line untouched when the binary is not found (kakehashi then
--- inherits PATH, same as a bare name).
---@param line string
---@return string
local function resolve_cmd_line(line)
  local head, binary, rest = line:match('^(%s*cmd%s*=%s*%[%s*)"([^"]*)"(.*)$')
  if not head then
    return line
  end
  local resolved = vim.fn.exepath(binary)
  if resolved == '' or resolved == binary then
    return line
  end
  return head .. '"' .. resolved .. '"' .. rest
end

--- Concatenate the kakehashi-lspconfig fragments for the bridged servers,
--- resolving each fragment's `cmd` first binary via exepath (mise shims)
--- so nvim launched without mise on PATH can still spawn the children
--- (the fork resolved these at bridge time; fragments ship bare names).
---@return string -- path to the built lsp.toml
local function build_lsp_toml()
  vim.fn.mkdir(kh_cache, 'p')
  local path = vim.fs.joinpath(kh_cache, 'lsp.toml')

  local lspconfig_path = find_plugin_path('kakehashi%-lspconfig$')
  if not lspconfig_path then
    vim.notify(
      '[kakehashi] kakehashi-lspconfig not on rtp; '
        .. 'bridged servers will not be configured',
      vim.log.levels.WARN
    )
    return path
  end

  local lines = {}
  local lsp_dir = vim.fs.joinpath(lspconfig_path, 'lsp')
  for _, name in ipairs(config.bridged_servers) do
    local fragment = vim.fs.joinpath(lsp_dir, name .. '.toml')
    if vim.fn.filereadable(fragment) == 1 then
      vim.list_extend(
        lines,
        vim.tbl_map(resolve_cmd_line, vim.fn.readfile(fragment))
      )
      table.insert(lines, '') -- blank line between fragments
    else
      vim.notify(
        ('[kakehashi] missing fragment for bridged server: %s'):format(fragment),
        vim.log.levels.WARN
      )
    end
  end

  vim.fn.writefile(lines, path)
  return path
end

--- Generate the emmylua workspace.library for the running nvim runtime.
--- Dynamic paths (vim.env.VIMRUNTIME + nvim runtime lua dirs) cannot live
--- in the static kakehashi.toml. library must stay a FLAT array of path
--- strings (an invalid EmmyrcWorkspacePathItem makes emmylua fall back to
--- defaults, re-introducing `undefined global variable: vim`).
---@return string -- path to the generated library.toml
local function build_library_toml()
  local library = vim.tbl_filter(
    function(path)
      return path ~= nil and path ~= ''
    end,
    vim.list_extend(
      { vim.env.VIMRUNTIME },
      vim.api.nvim_get_runtime_file('lua', true)
    )
  )

  local lines = {
    '# Generated by after/lsp/kakehashi.lua — do not edit.',
    '[languageServers.emmylua_ls.settings.emmylua.workspace]',
    'library = [',
  }
  for _, path in ipairs(library) do
    table.insert(lines, '  ' .. vim.inspect(path) .. ',')
  end
  table.insert(lines, ']')

  local path = vim.fs.joinpath(kh_cache, 'library.toml')
  vim.fn.writefile(lines, path)
  return path
end

-- ==========================================================================
-- kakehashi client config
-- ==========================================================================

local home = vim.env.HOME or '~'

-- Standard user config location (chezmoi-managed; also holds the dpp
-- parser/queries/grammar moved out of this repo).
local kakehashi_toml = vim.fs.joinpath(
  vim.env.XDG_CONFIG_HOME or vim.fs.joinpath(home, '.config'),
  'kakehashi',
  'kakehashi.toml'
)
if vim.fn.filereadable(kakehashi_toml) ~= 1 then
  vim.notify(
    ('[kakehashi] missing %s (chezmoi-managed; run `chezmoi apply`)'):format(
      kakehashi_toml
    ),
    vim.log.levels.WARN
  )
end

local cmd = { 'kakehashi' }
for _, file in ipairs({
  build_lsp_toml(),
  kakehashi_toml,
  build_library_toml(),
}) do
  table.insert(cmd, '--config-file')
  table.insert(cmd, file)
end

local init_options = {
  searchPaths = vim.tbl_filter(function(path)
    return path ~= nil and path ~= ''
  end, {
    -- ~/.local/share/kakehashi (server data dir)
    vim.fs.joinpath(home, '.local', 'share', 'kakehashi'),
    -- ~/.config/kakehashi: dpp parser + queries (chezmoi-managed)
    vim.fs.dirname(kakehashi_toml),
    -- The plugin's own rtp entry (bundled queries)
    find_plugin_path('kakehashi%.nvim$'),
  }),
  languages = config.languages(),
}

return {
  cmd = cmd,
  filetypes = config.filetypes(),
  init_options = init_options,
  on_init = function(client)
    -- Prefer semanticTokens/full/delta over range requests.
    local provider = client.server_capabilities.semanticTokensProvider
    if provider then
      provider.range = false
    end
  end,
  on_attach = function(client, bufnr)
    -- dpp: treesitter owns highlighting (lua parser + luadoc injections,
    -- started in after/ftplugin/dpp.lua). kakehashi's tokens for dpp are
    -- only host markers (injected lua tokens depend on emmylua's slow
    -- analysis), so the token-based takeover below would leave the buffer
    -- uncolored. Prefer treesitter to LSP semantic tokens:
    -- https://blog.atusy.net/2025/07/15/prefer-luadoc-to-luals-semantictokens
    if vim.bo[bufnr].filetype == 'dpp' then
      vim.lsp.semantic_tokens.enable(false, {
        bufnr = bufnr,
        client_id = client.id,
      })
      return
    end

    -- Let kakehashi own highlighting once semantic tokens arrive
    -- (scripts/minimal_init.lua, kakehashi README Quick Start).
    vim.api.nvim_create_autocmd('LspTokenUpdate', {
      buffer = bufnr,
      once = true,
      callback = function()
        vim.opt_local.syntax = 'OFF'
        vim.treesitter.stop(bufnr)
      end,
    })
  end,
}
