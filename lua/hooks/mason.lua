-- lua_source {{{
  require('mason').setup()

  -- https://zenn.dev/glmlm/articles/neovim-mason-lspconfig-20250218
  local registry = require("mason-registry")
  local pkg_specs_all = registry.get_all_package_specs()

  local lspconfig_to_pkg = {}
  for _, pkg_spec in ipairs(pkg_specs_all) do
    if vim.tbl_get(pkg_spec, "neovim", "lspconfig") ~= nil then
      local key = pkg_spec.neovim.lspconfig
      local value = pkg_spec.name or key
      lspconfig_to_pkg[key] = value
    end
  end

  local servers = {
    'denols',
    'emmylua_ls',
    'gopls',
    --'lua_ls',
    'pyright',
    'rust_analyzer',
    'vtsls',
  }

  local packages = {}
  for _, lspcfg_name in ipairs(servers) do
    local lsp = lspconfig_to_pkg[lspcfg_name] or lspcfg_name
    table.insert(packages, lsp)
  end

  registry.refresh(function()
    for _, pkg_name in ipairs(packages) do
      if not registry.is_installed(pkg_name) then
        local pkg = registry.get_package(pkg_name)
        pkg:install()
      end
    end
  end)

  vim.lsp.config('*', {
    capabilities = require("ddc_source_lsp").make_client_capabilities(),
  })

  vim.lsp.config('emmylua_ls', {
    on_init = function(client)
      client.config.settings.Lua = vim.tbl_deep_extend(
          'force', client.config.settings.Lua, {
        workspace = { library = vim.api.nvim_get_runtime_file('', true) },
      })
    end,
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        workspace = { checkThirdParty = false },
      },
    },
    workspace_required = true,
  })

  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        runtime = {
          -- Tell the language server which version of Lua you're using
          -- (most likely LuaJIT in the case of Neovim)
          version = 'LuaJIT',
        },
        diagnostics = {
          -- Get the language server to recognize the `vim` global
          globals = {
            'vim',
            'require',
          },
        },
        semantic = {
          -- Disable semantic token feature.
          -- Because treesitter highlight is better.
          enable = false,
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          library = vim.api.nvim_get_runtime_file("", true),
        },
        telemetry = {
          -- Do not send telemetry data
          enable = false,
        },
      },
    },
  })

  vim.lsp.config('vtsls', {
    root_dir = function(bufnr, callback)
      -- NOTE: Must be node directory
      if vim.fn.findfile('package.json', '.;') ~= '' then
        callback(vim.fn.getcwd())
      end
    end,
    workspace_required = true,
  })

  vim.lsp.config('denols', {
    -- Disable nest.land imports
    -- https://github.com/neovim/nvim-lspconfig/pull/2793
    settings = {
      deno = {
        lint = true,
        unstable = true,
        suggest = {
          imports = {
            autoDiscover = false,
            hosts = {
              ['https://x.nest.land'] = false,
            },
          },
        },
      },
    },
    root_markers = {
      'deno.json',
      'deno.jsonc',
      'deps.ts',
    },
    workspace_required = false,
  })

  vim.lsp.enable(servers)
-- }}}

