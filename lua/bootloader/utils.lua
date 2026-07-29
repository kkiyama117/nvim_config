-- TODO
local M = {}

-----------------------------------------------------------------------------
-- functions
-----------------------------------------------------------------------------
-- Install plugins from url to dest_path.
-- That does what `dpp-ext-intaller` and `dpp-protocol-git` do manually
-- only for initial setup or fallback of dpp.
local function install_github_plugin(url, dest_path, is_debug)
	vim.notify(("[DPP] cloning %s"):format(plugin_name), vim.log.levels.INFO)
	vim.fn.system({
		"git",
		"clone",
		"--filter",
		"blob:none",
		"https://github.com/" .. plugin_name,
		dest_path,
	})
end

return M

