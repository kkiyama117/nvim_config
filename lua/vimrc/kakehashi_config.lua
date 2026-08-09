--- kakehashi bridge configuration (vimrc-owned).
---
--- kakehashi is the single Neovim LSP client; downstream servers (pyright,
--- gopls, …) run as bridged child processes. Keep `bridged_servers` in sync
--- with the LSP server installs in ~/.config/mise/config.toml and the
--- `enabled` entries in ~/.config/kakehashi/kakehashi.toml (the
--- kakehashi-lspconfig fragments ship with `enabled = false`). Per-server
--- settings live in ~/.config/kakehashi/kakehashi.toml; client filetypes
--- table live here.
local M = {}

---@type string[]
M.bridged_servers = {
  'denols',
  'emmylua_ls',
  'gopls',
  'pyright',
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
--- Also used as the kakehashi client `filetypes` list so kakehashi attaches.
---@type table<string, string[]>
M.server_filetypes = {
  denols = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
  },
  emmylua_ls = {
    'lua',
    -- dpp: dpp.vim hooks files (*.dpp) attach kakehashi via this entry
    -- (filetypes() collection). The emmylua bridge itself runs on the
    -- injected lua virtual documents (Route 2, languages.dpp.bridge.lua),
    -- not on the host document (emmylua keys by URI extension, so host
    -- .dpp docs are ignored anyway). See .agents/issues/dpp-filetype.md.
    'dpp',
  },
  gopls = { 'go', 'gomod', 'gowork', 'gotmpl' },
  pyright = { 'python' },
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
--- Sent via LSP initialize; merges with the --config-file layers
--- (lsp.toml + kakehashi.toml + library.toml, built by
--- after/lsp/kakehashi.lua). No didChangeConfiguration, so no
--- settings.kakehashi wire shape and no diagnostics re-pull race.
---@return table
function M.languages()
  local languages = {
    ['_'] = {
      layers = {
        aggregation = {
          -- Pull-only diagnostics: seal the publishDiagnostics wire so
          -- nvim gets a single set via textDocument/diagnostic. kakehashi
          -- folds push-driven servers' cached diagnostics into pull
          -- answers, so nothing is lost. The languageServers are already
          -- configured at spawn (--config-file), so the fork's re-pull
          -- workaround (bridge.lua polling effectiveConfiguration) is
          -- unnecessary.
          ['textDocument/publishDiagnostics'] = { priorities = {} },
        },
      },
    },
  }

  for _, lang in ipairs(M.host_bridge_languages) do
    languages[lang] = {
      bridge = {
        _self = { enabled = true },
      },
    }
  end

  -- dpp (dpp.vim hooks file, *.dpp): custom tree-sitter-dpp grammar
  -- (Route 2, .agents/issues/dpp-filetype.md D1b) parses hook blocks;
  -- queries/dpp/injections.scm injects each block's content lines as lua
  -- (wrapper lines `lua << EOF` / `EOF` excluded), and the injected
  -- virtual documents (kakehashi-virtual-uri-*.lua) are bridged to
  -- emmylua_ls — the only path that reaches emmylua, which keys
  -- documents by URI extension.
  --
  -- viml-format blocks (`" hook_* {{{` / `" target_filetype {{{`) inject
  -- vim (the vim grammar parses the `lua << EOF` heredoc wrapper natively
  -- and injects the body as lua for kakehashi's own features). No bridge
  -- is configured for the vim layer: kakehashi only opens virtual
  -- documents on servers that handle the injection language, and no
  -- bridged server handles vim — the nested lua therefore does not reach
  -- emmylua (viml-format dpp files get no LSP features; lua-format ones
  -- keep the emmylua bridge above).
  local xdg_config = vim.env.XDG_CONFIG_HOME
    or vim.fs.joinpath(vim.env.HOME or '~', '.config')
  languages.dpp = {
    parser = vim.fs.joinpath(xdg_config, 'kakehashi', 'parser', 'dpp.so'),
    bridge = {
      lua = {
        aggregation = {
          ['_'] = { priorities = { 'emmylua_ls' } },
        },
      },
    },
  }

  languages.markdown = {
    bridge = {
      -- emmylua_ls (not lua-language-server); see the vimrc's
      -- lua/hooks/nvim-lspconfig.dpp.
      lua = {
        aggregation = {
          ['_'] = { priorities = { 'emmylua_ls' } },
        },
      },
      python = {
        aggregation = {
          ['textDocument/completion'] = {
            priorities = { 'pyright' },
            maxFanOut = 1,
          },
        },
      },
      typescript = {
        aggregation = {
          ['textDocument/completion'] = {
            priorities = { 'vtsls', 'denols' },
            maxFanOut = 1,
          },
        },
      },
      javascript = {
        aggregation = {
          ['textDocument/completion'] = {
            priorities = { 'vtsls', 'denols' },
            maxFanOut = 1,
          },
        },
      },
    },
  }

  languages.rmd = { base = 'markdown' }
  languages.quarto = { base = 'markdown' }

  return languages
end

return M
