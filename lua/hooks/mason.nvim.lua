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

local servers = { 'denols', 'emmylua_ls', 'gopls', 'pyright', 'rust_analyzer', 'tombi', 'vtsls' }

local packages = {}
for _, lspcfg_name in ipairs(servers) do
	local lsp = lspconfig_to_pkg[lspcfg_name] or lspcfg_name
	table.insert(packages, lsp)
end

-- Non-LSP tools (formatters, linters, debuggers, etc.)
table.insert(packages, 'stylua')
table.insert(packages, 'codelldb')

registry.refresh(function ()
	for _, pkg_name in ipairs(packages) do
		if not registry.is_installed(pkg_name) then
			local pkg = registry.get_package(pkg_name)
			pkg:install()
		end
	end
end)

vim.lsp.config('*', {
	capabilities = require("ddc_source_lsp").make_client_capabilities()
})

-- vim.lsp.config('tombi', {
-- })
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
						['https://x.nest.land'] = false
					}
				}
			}
		}
	},
	root_markers = {
		'deno.json',
		'deno.jsonc',
		'deps.ts'
	},
	workspace_required = false
})

-- emmylua_ls reads settings under the `emmylua` namespace (NOT `Lua`, which
-- belongs to sumneko/lua-language-server). Using `Lua` is why `vim` was
-- reported as an undefined global.
vim.lsp.config(
	'emmylua_ls',
	{
		on_init = function (client)
			-- If the workspace has its own emmylua/lua config file, defer to it.
			if client.workspace_folders then
				local path = client.workspace_folders[1].name
				if path ~= vim.fn.stdpath('config')
					and (vim.uv.fs_stat(path .. '/.emmyrc.json')
						or vim.uv.fs_stat(path .. '/.luarc.json')) then
					client.config.settings = {}
					return
				end
			end
		end,
		settings = {
			emmylua = {
				runtime = { version = 'LuaJIT' },
				diagnostics = { globals = { 'vim' } },
				workspace = {
					-- library must be a FLAT array of path strings; nesting the array
          -- returned by nvim_get_runtime_file produces an invalid
          -- EmmyrcWorkspacePathItem and makes emmylua fall back to defaults
          -- (re-introducing the `undefined global variable: vim` error).
					library = vim.list_extend(
						{ vim.env.VIMRUNTIME }, vim.api.nvim_get_runtime_file('lua', true)
					)
				}
			}
		},
		workspace_required = false
	}
)

vim.lsp.config('vtsls', {
	root_dir = function (bufnr, callback)
		-- NOTE: Must be node directory
		if vim.fn.findfile('package.json', '.;') ~= '' then
			callback(vim.fn.getcwd())
		end
	end,
	workspace_required = true
})

vim.lsp.enable(servers)
-- }}}
