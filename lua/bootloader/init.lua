local M = {}
local is_debug = vim.env.NVIM_DEBUG == "true"
local my_autocmds = vim.api.nvim_create_augroup("MyAutoCmd", { clear = false })

-- Deno binary path for denops
vim.g["denops#deno"] =
	vim.fn.abspath(vim.fs.joinpath(vim.env.MISE_DATA_DIR, "installs", "deno", "latest", "bin", "deno") or "deno")

-- minimum_deps
M.minimum_deps = { "Shougo/dpp.vim", "Shougo/dpp-ext-lazy" }

-- plugins that is needed to load dpp and other plugins
M.normal_deps = {
	"Shougo/dpp-ext-toml",
	"Shougo/dpp-ext-local",
	"Shougo/dpp-ext-installer",
	"Shougo/dpp-ext-packspec",
	"Shougo/dpp-protocol-git",
	"Shougo/dpp-protocol-http",
	"vim-denops/denops.vim",
	"Shougo/cmdline.vim",
}
local function load_() end

return M

