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
local dpp_denops_script = vim.fs.joinpath(vim.g.nvim_config_home, "denops", "dpp.ts")

-- Minimum plugins to load dpp
-- That should included in `deps/dpp.toml`
local minimum_deps = {
  "Shougo/dpp.vim",
  "Shougo/dpp-ext-lazy",
}
-- plugins used to install plugins with dpp
-- That should included in `deps/dpp.toml` except `denops.vim`
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
-- https://github.com/Shougo/shougo-s-github/blob/master/vim/rc/dpp.vim
local function initialize_dpp()
  -- check minimum requirements are installed
  load_plugins(minimum_deps)
  -- load dpp
  local dpp = require("dpp")

  -- call `dpp#min#load_state` and check it works
  if dpp.load_state(dpp_cache_home) then
    -- install and load `denops.vim` and `dpp plugins` to load dpp
    load_plugins(normal_deps)
    -- Manual load is needed
    if vim.fn.has("nvim") == 1 then
      vim.cmd([[runtime! plugin/denops.vim]])
    end
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
    -- check config is updated and update cache
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.lua,*.vim,*.toml,*.ts,vimrc,.vimrc",
      group = my_autocmds,
      callback = function()
        local updated = vim.fn["dpp#check_files"](dpp_cache_home)
        if type(updated) == "table" and not vim.tbl_isempty(updated) then
          dpp.make_state(dpp_cache_home, dpp_denops_script)
        end
      end,
    })
    -- check toml deps are updated and new plugins are needed
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.toml",
      group = my_autocmds,
      callback = function()
        local not_installed = vim.fn["dpp#sync_ext_action"]("installer", "getNotInstalled")
        if type(not_installed) == "table" and not vim.tbl_isempty(not_installed) then
          dpp.async_ext_action("installer", "install")
        end
      end,
    })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:makeStatePost",
    group = my_autocmds,
    callback = function()
      vim.notify("dpp make_state() is done", vim.log.levels.WARN)
    end,
  })
end

-----------------------------------------------------------------------------
-- load dpp
initialize_dpp()

return M
