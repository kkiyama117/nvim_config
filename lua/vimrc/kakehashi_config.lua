--- Shared kakehashi / Mason LSP bridge configuration.
---
--- kakehashi is the single Neovim LSP client; downstream servers (pyright,
--- gopls, …) run as bridged child processes. Keep `bridged_servers` in sync
--- with Mason package installs in lua/hooks/mason.nvim.lua.
local M = {}

---@type string[]
M.bridged_servers = {
  'denols',
  'emmylua_ls',
  'gopls',
  'pyright',
  'rust_analyzer',
  'tombi',
  'vtsls',
}

--- Document languages that should forward LSP to bridged servers on the host
--- buffer (`bridge._self`). Tree-sitter language names, not always Vim filetypes.
---@type string[]
M.host_bridge_languages = {
  'go',
  'javascript',
  'lua',
  'python',
  'rust',
  'toml',
  'typescript',
}

--- Markdown-family filetypes always handled by kakehashi (injection + host).
---@type string[]
M.markdown_filetypes = {
  'markdown',
  'markdown_inline',
  'quarto',
  'rmd',
}

--- Per-server Vim filetypes (mirror nvim-lspconfig defaults; keep in sync).
---@type table<string, string[]>
M.server_filetypes = {
  denols = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  emmylua_ls = { 'lua' },
  gopls = { 'go', 'gomod', 'gowork', 'gotmpl' },
  pyright = { 'python' },
  rust_analyzer = { 'rust' },
  tombi = { 'toml' },
  vtsls = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
}

--- Collect Vim filetypes kakehashi should attach to.
---@return string[]
function M.filetypes()
  local fts = vim.list_extend({}, M.markdown_filetypes)
  local seen = {}
  for _, ft in ipairs(fts) do
    seen[ft] = true
  end

  for _, name in ipairs(M.bridged_servers) do
    for _, ft in ipairs(M.server_filetypes[name] or {}) do
      if not seen[ft] then
        seen[ft] = true
        fts[#fts + 1] = ft
      end
    end
  end

  return fts
end

--- Build kakehashi `init_options.languages` bridge table.
---@return table
function M.languages()
  local languages = {
    ['_'] = { autoInstall = true },
  }

  for _, lang in ipairs(M.host_bridge_languages) do
    languages[lang] = {
      bridge = {
        _self = { enabled = true },
      },
    }
  end

  languages.markdown = {
    bridge = {
      -- emmylua_ls (not lua-language-server); see lua/hooks/mason.nvim.lua.
      lua = {
        aggregation = {
          ['_'] = { priorities = { 'emmylua_ls' } },
        },
      },
      python = {
        aggregation = {
          ['textDocument/completion'] = { priorities = { 'pyright' }, maxFanOut = 1 },
        },
      },
      rust = {
        aggregation = {
          ['_'] = { priorities = { 'rust_analyzer' } },
        },
      },
      typescript = {
        aggregation = {
          ['textDocument/completion'] = { priorities = { 'vtsls', 'denols' }, maxFanOut = 1 },
        },
      },
      javascript = {
        aggregation = {
          ['textDocument/completion'] = { priorities = { 'vtsls', 'denols' }, maxFanOut = 1 },
        },
      },
    },
  }

  languages.rmd = { base = 'markdown' }
  languages.quarto = { base = 'markdown' }

  return languages
end

return M
