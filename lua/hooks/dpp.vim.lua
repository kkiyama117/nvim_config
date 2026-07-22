-- lua_add {{{
-- ==========================================================================
-- Install missing plugins and update plugins with upstream changes.

-- NOTE: getNotUpdated contacts the remote (git ls-remote / GitHub API), so the
-- sync call blocks Neovim for a moment.  That is acceptable for a manual
-- command but keep it out of startup-critical paths.
-- ==========================================================================
local function dpp_install_update(opts)
	if not (vim.g.dpp and vim.g.dpp.settings and vim.g.dpp.settings.base_path) then
		vim.notify("dpp is not initialized", vim.log.levels.ERROR)
		return
	end
	if not vim.g.loaded_denops then
		vim.notify("denops is not ready yet; retry after DenopsReady", vim.log.levels.ERROR)
		return
	end

	local names = (opts and opts.fargs) or {}
	local names_of = function (plugins)
		return vim.tbl_map(function (p) return p.name end, plugins)
	end

	-- 1. Install missing plugins.
	local not_installed = vim.fn["dpp#sync_ext_action"]("installer", "getNotInstalled", { names = names })
	if type(not_installed) == "table" and not vim.tbl_isempty(not_installed) then
		local list = names_of(not_installed)
		vim.notify(("[dpp] installing %d: %s"):format(#list, table.concat(list, ", ")), vim.log.levels.INFO)
		vim.fn["dpp#async_ext_action"]("installer", "install", { names = list })
	else
		vim.notify("[dpp] no missing plugins", vim.log.levels.INFO)
	end

	-- 2. Update plugins with upstream changes.
	local not_updated = vim.fn["dpp#sync_ext_action"]("installer", "getNotUpdated", { names = names })
	if type(not_updated) == "table" and not vim.tbl_isempty(not_updated) then
		local list = names_of(not_updated)
		vim.notify(("[dpp] updating %d: %s"):format(#list, table.concat(list, ", ")), vim.log.levels.INFO)
		vim.fn["dpp#async_ext_action"]("installer", "update", { names = list })
	else
		vim.notify("[dpp] no updates available", vim.log.levels.INFO)
	end
end
-- ==========================================================================
vim.api.nvim_create_user_command("DppInstallUpdate", dpp_install_update, {
	desc = "Install missing plugins and update plugins with upstream changes",
	nargs = "*",
	complete = function ()
		local plugins = (vim.g.dpp and vim.g.dpp.state or {}).plugins or {}
		return vim.tbl_keys(plugins)
	end
})
-- }}}
