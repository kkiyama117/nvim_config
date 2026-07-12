-- Pre-dpp loader: install/clone minimum plugins and bootstrap dpp.vim.
-- Runs at require-time (init.lua calls only `require('dpp_loader')`).

-- Prepare Lua module and AuGroup
local M = {}
local my_autocmds = vim.api.nvim_create_augroup("MyAutoCmd", { clear = false })

local home_dir       = vim.env.HOME
local xdg_cache_home = vim.env.XDG_CACHE_HOME
  or vim.fn.fnamemodify(home_dir, ":p:h") .. "/.cache"
local xdg_config_home = vim.env.XDG_CONFIG_HOME
  or vim.fn.fnamemodify(home_dir, ":p:h") .. "/.config"
-- cache of dpp
-- They should be matched with `dpp-ext` plugins
local dpp_cache_home = vim.fs.joinpath(xdg_cache_home, "dpp")
local dpp_cache_github = vim.fs.joinpath(dpp_cache_home, "repos", "github.com")
local dpp_cache_local = vim.fs.joinpath(dpp_cache_home, "local")
-- 
local dpp_denops_script = vim.fs.joinpath(xdg_config_home, "nvim", "denops", "dpp.ts")

-- Minimum plugins to load dpp
local minimum_deps = {
  "Shougo/dpp.vim",
  "Shougo/dpp-ext-lazy",
}
-- plugins used to install plugins with dpp
local normal_deps = {
  "Shougo/dpp-ext-installer",
  "Shougo/dpp-ext-local",
  "Shougo/dpp-ext-packspec",
  "Shougo/dpp-ext-toml",
  "Shougo/dpp-protocol-git",
  "vim-denops/denops.vim",
}

-----------------------------------------------------------------------------
-- functions
-----------------------------------------------------------------------------

-- Return the destination that plugin should be placed into.
local function dest_path(plugin_name)
  return vim.fs.joinpath(dpp_cache_github, plugin_name)
end

-- check plugin is installed and can be used
-- TODO: Check not only `is_dir` but also other things
local function is_plugin_ready(plugin_name, dest_path)
  return vim.fn.isdirectory(dest_path) ~= 0
end

-- Install one plugin
-- `name` should be `username/name` pattern
-- And return `dest`, local path that installed 
local function install_github_plugin(plugin_name, dest_path)
  vim.notify(("[dpp] cloning %s"):format(plugin_name), vim.log.levels.INFO)
  vim.fn.system({
    "git", "clone", "--filter", "blob:none",
    "https://github.com/" .. plugin_name, dest_path,
  })
  if vim.v.shell_error ~= 0 then
    vim.notify(("[dpp] failed to clone %s"):format(plugin_name), vim.log.levels.ERROR)
    return nil
  end
  return dest_path
end

-- load (and install if not exist) all plugins
local function load_plugins(list_of_plugin)
  for _, name in ipairs(list_of_plugin) do
    local plugin_dest_path = dest_path(name)
    if not is_plugin_ready(name, plugin_dest_path) then
      local _installed_path = install_github_plugin(name, plugin_dest_path)
    end
    vim.opt.runtimepath:prepend(vim.fs.normalize(plugin_dest_path))
  end
end

-----------------------------------------------------------------------------
-- Main
-----------------------------------------------------------------------------
-- Called when initialize dpp
local function initialize_dpp()
  -- check minimum requirements are installed
  load_plugins(minimum_deps)
  -- load dpp
  local dpp = require("dpp")

  -- call `dpp#min#load_state` and check it works
  if dpp.load_state(dpp_cache_home) then
    -- install and load `denops.vim` and `dpp plugins`
    load_plugins(normal_deps)
    -- NOTE: Manual load is needed for Neovim because "--noplugin" is used to optimize.
    if vim.fn.has("nvim") == 1 then
	    vim.cmd([[ runtime! plugin/denops.vim ]])
    end
    -- If load state is failed, call `make_state`
    vim.api.nvim_create_autocmd("User", {
      pattern = "DenopsReady",
      group = my_autocmds,
      once = true,
      callback = function()
        vim.notify("dpp load_state() is failed", vim.log.levels.WARN)
        dpp.make_state(dpp_cache_home, dpp_denops_script)
      end,
    })
  else
    -- Update cache file alutomatically when the config is updated
    -- See `:h dpp-faq-4`
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.lua,*.vim,*.toml,*.ts,vimrc,.vimrc",
      group = my_autocmds,
      callback = function()
	if #dpp.check_files(dpp_cache_home) ~= 0 then
	  dpp.make_state(dpp_cache_home, dpp_denops_script)
	end
      end,
    })
    -- Install new plugins if not exist
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.toml",
      group = my_autocmds,
      callback = function()
	-- We need `dpp-ext-installer`
	if #dpp.sync_ext_action("installer", "getNotInstalled") ~= 0 then
	  dpp.async_ext_action("installer", "install")
	end
      end,
    })

  end
  -- If dpp.make_state() is finished, notify (with AutoCmd)
  vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:makeStatePost",
    group = my_autocmds,
    callback = function()
      vim.notify("dpp make_state() is done", vim.log.levels.INFO)
    end,
  })
  -- Add user command of alias `dpp: update`
  -- TODO: move to other place
  vim.api.nvim_create_user_command("DppUpdate", function()
    vim.fn["dpp#async_ext_action"]("installer", "update")
  end, {})
end

-----------------------------------------------------------------------------
-- load dpp
initialize_dpp()

return M
