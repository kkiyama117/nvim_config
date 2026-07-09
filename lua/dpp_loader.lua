local M = {}
local my_utils = require('utils')
local joinpath = vim.fs.joinpath

------------------------------------------------------------------------------
-- install plugins manually and add to runtimepath if not installed
------------------------------------------------------------------------------

-- function to check repository exists and clone if not found.
--- 初回起動時にプラグインのダウンロードとruntimepathに追加する
---@param plugin string user_name/plugin_name
---@param base? string
---@param devDir? 
local function _dpp_init_github_plugin(plugin, base, devDir)
  local local_dir = nil
  local result = false

  -- search from local dev folder
  if not devDir == nil then
	  vim.notify("Local dev plugin loaded", vim.log.levels.DEBUG)
    local_dir = joinpath(devDir, vim.fn.fnamemodify(plugin, ':t'))
    if my_utils.is_dir(local_dir) then
      -- Add path to runtimepath
      vim.opt.runtimepath:prepend(vim.fn.substitute(vim.fn.fnamemodify(local_dir,':p:h'),'[/\\]$','',''))
      return 2
    end
  end
  
  -- check dpp cache
  local_dir = joinpath(base, plugin)
	--vim.notify("Global plugin loaded", vim.log.levels.DEBUG)
  if not my_utils.is_dir(local_dir) then
    vim.notify("Plugin not found. Install", vim.log.levels.INFO)
    local _command = table.concat({'git', 'clone', 'https://github.com/' .. plugin,  local_dir, "--filter blob:none"}, " ")
    os.execute(_command)
    if not vim.v.shell_error == 0 then
      vim.notify(plugin .. "install failed", vim.log.levels.ERROR)
      return 0
    else
      vim.notify(plugin .. "installed successfully", vim.log.levels.INFO)
    end
  end
  -- Add dir to runtimepath if not exists
  --local new_plugin_runtime_path = vim.fn.substitute(vim.fn.fnamemodify(local_dir,':p:h'),'[/\\]$','','')
  local new_plugin_runtime_path = local_dir
  --vim.notify(new_plugin_runtime_path, vim.log.levels.DEBUG)
  vim.opt.runtimepath:prepend(new_plugin_runtime_path)
  return 1
end

-- base_dir is xdg_config_home/nvim
-- TODO: USE THIS
local function _gather_check_files(base_dir)
  local glob_patterns = {
      "**/*.lua",
      "**/*.toml",
      "**/*.ts",
  }
  local check_files = {}
  for _, glob_pattern in pairs(glob_patterns) do
    table.insert(check_files, vim.fn.globpath(base_dir, glob_pattern, true, true))
    --table.insert(check_files, vim.fn.globpath("~/dotfiles/config/nvim", glob_pattern, true, true))
  end
  return vim.tbl_flatten(check_files)
end

--" call dpp installer command
local function _auto_install_plugins(dpp)
  local notInstallPlugins = vim.iter(vim.tbl_values(dpp.get()))
      :filter(function(p)
          return vim.fn.isdirectory(p.rtp) == 0
      end)
      :totable()
  local has_not_installed_plugins = #notInstallPlugins > 0
  
  if has_not_installed_plugins then
      vim.fn["denops#server#wait_async"](function()
          dpp.async_ext_action("installer", "install")
      end)
  end
end

local function _dpp_setup(dppCache, dppConfigScript)
  local dpp = require("dpp")
  local my_autocmds = vim.api.nvim_create_augroup("MyAutoCmd", { clear = true })

  -- if cache is old
  if dpp.load_state(dppCache) then
    vim.fn["denops#server#wait_async"](function()
            dpp.make_state(dppCache, dppConfigScript, "nvim")
            vim.api.nvim_create_autocmd("User", {
                pattern = "Dpp:makeStatePost",
                group = my_autocmds,
                callback = function()
                    dpp.load_state(dppCache)
		                -- install plugins
                    _auto_install_plugins(dpp)
                    vim.api.nvim_create_autocmd("User", {
                        pattern = "Dpp:makeStatePost",
                        group = my_autocmds,
                        callback = function()
                            vim.cmd.quit({ bang = true })
                        end,
                    })
                --vim.keymap.set('n', '<Leader>p', ':DppUpdate<CR>', {remap = true})
                end,
                once = true,
                nested = true,
            })
    end)
  else
    --vim.api.nvim_create_autocmd("BufWritePost", {
    --  pattern = "*.toml,*.lua",
    --  group = my_autocmds,
    --  command = _auto_install_plugins(dpp)
    --})
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.lua,*.vim,*.toml,*.ts,vimrc,.vimrc",
      group = my_autocmds,
      callback = function()
	      vim.notify("dpp check_files() is run", vim.log.levels.INFO)
        dpp.check_files()
      end,
    })
  end
    -- create `DppUpdate` command
    vim.api.nvim_create_user_command('DppUpdate', function()
      vim.fn['dpp#async_ext_action']('installer', 'update')
    end, {} )
  vim.api.nvim_create_autocmd("User", {
        pattern = "Dpp:makeStatePost",
        group = my_autocmds,
        callback = function()
          vim.notify("dpp make_state() is done", vim.log.levels.INFO)
        end,
  })
end 

-----------------------------------------------------------------------------
-- load dpp
-----------------------------------------------------------------------------
--init.luaで呼び出すdpp.vimの初期設定
function M.setup()
  -- Used variables in this lua file
  local home_dir = vim.env.HOME
  local xdg_cache_home = vim.env.XDG_CACHE_HOME or joinpath(fnamemodify(home_dir,":p:h"), ".cache") or vim.fn.stdpath("cache") 
  --" dpp cache base folder
  local dppCache = joinpath(xdg_cache_home, "dpp")
  local dppGithubBase = joinpath(dppCache, "repos", "github.com")
  -- " dev plugin folder
  local devDir = joinpath(home_dir, "programs", "nvim")
  -- " dpp config with typescript and denops
  local dppConfigScript = joinpath(vim.g.nvim_config_home, "typescript", "dpp.ts")

  -- NOTE: dpp.vim path must be added to call dpp functions
  local minimum_loaded = {
      "Shougo/dpp-ext-local",
      "Shougo/dpp-ext-lazy",
      "Shougo/dpp-ext-packspec",
      "Shougo/dpp-ext-toml",
      "Shougo/dpp-ext-installer",
      "Shougo/dpp-protocol-git",
      "Shougo/dpp.vim",
      "vim-denops/denops.vim",
  }

  -- 初回起動時に初期化 and download
  for _,v in pairs(minimum_loaded) do
    --vim.notify("dpp plugin force load: " .. v, vim.log.levels.DEBUG)
    _dpp_init_github_plugin(v, dppGithubBase)
  end

  -- setup
  _dpp_setup(dppCache, dppConfigScript)
  vim.notify("DPP LOAD FINISHED", vim.log.levels.DEBUG)
end

return M

