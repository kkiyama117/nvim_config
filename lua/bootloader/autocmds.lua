--- Auto-update hooks for dpp state and plugin sync.

local M = {}
local is_debug = vim.g['vimrc#is_debug'] == 'true'

local my_autocmds = vim.api.nvim_create_augroup('vimrc', { clear = false })

-- ==========================================================================
-- Utilities
-- ==========================================================================
--- Return whether `file` lies inside the `vim.env.NVIM_CONFIG_HOME`.
---
---@param file string Absolute or relative path
---@return boolean
local function is_under_nvim_config_home(file)
  local nvim_config_home = vim.fs.normalize(vim.env.NVIM_CONFIG_HOME)
  if file == '' then
    return false
  end
  file = vim.fs.normalize(file)
  local sep = package.config:sub(1, 1)
  return file == nvim_config_home
    or vim.startswith(file, nvim_config_home .. sep)
end

-- ==========================================================================
-- AutoCmds
-- ==========================================================================

--- Deno fires Dpp:makeStatePost only after both state.vim and startup.vim
--- are written, so this is the reliable "make_state finished" signal.
---
--- Verifies the rebuilt state is loadable before restarting to prevent
--- infinite restart loops when the state is consistently broken.
---
---@return boolean true if setup finished successfully.
local function setup_autocmd_make_state_post()
  vim.api.nvim_create_autocmd('User', {
    pattern = 'Dpp:makeStatePost',
    group = vim.api.nvim_create_augroup('vimrc', { clear = false }),
    callback = function()
      vim.notify(
        'dpp make_state() may be done successfully',
        vim.log.levels.WARN
      )
      -- Verify the rebuilt state is actually loadable before restarting
      local cache_home = vim.g['vimrc#dpp#cache_home']
      if cache_home == nil then
        vim.notify(
          '[VIMRC#BOOTLOADER#AutoCmd]: cache_home not set, skip restart',
          vim.log.levels.ERROR
        )
        return
      end
      local ok, result = pcall(vim.fn['dpp#min#load_state'], cache_home)
      if ok and result == 0 then
        vim.notify(
          '[VIMRC#BOOTLOADER#AutoCmd]: state verified, restarting...',
          vim.log.levels.WARN
        )
        vim.cmd('restart +xall')
      else
        vim.notify(
          '[VIMRC#BOOTLOADER#AutoCmd]: state still broken after make_state, skip restart',
          vim.log.levels.ERROR
        )
      end
    end,
  })
  return true
end

local function setup_autocmd_load_state_failed(args)
  local dpp_cache_home = args.cache_home
  local dpp_cache_github = args.cache_github
  local dpp_denops_script = args.dpp_script
  if
    dpp_cache_home == nil
    or dpp_cache_github == nil
    or dpp_denops_script == nil
  then
    vim.notify('[VIMRC#BOOTLOADER#AutoCmd]: invalid args', vim.log.levels.ERROR)
    return false
  else
    -- if denops is ready, call dpp#make_state directly.
    -- Do NOT route through fallback F1 → dpp_update_force, because
    -- dpp#min#load_state already failed and dpp functions that check
    -- initialization (dpp#check_files, dpp#sync_ext_action, etc.) will
    -- refuse to work. dpp#make_state is designed to run without prior
    -- initialization and is the correct recovery path.
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DenopsReady',
      once = true,
      callback = function()
        vim.notify(
          '[VIMRC#BOOTLOADER#AutoCmd]: DenopsReady -> make_state',
          vim.log.levels.WARN
        )
        require('bootloader/dpp/make_state').run({
          cache_home = vim.g['vimrc#dpp#cache_home'],
          cache_github = vim.g['vimrc#dpp#cache_github'],
          dpp_script = vim.g['vimrc#dpp#denops_script'],
        })
      end,
    })
    vim.notify(
      '[VIMRC#BOOTLOADER#AutoCmd]: Wait DenopsReady',
      vim.log.levels.WARN
    )
  end
end

--- Register autocmds that react to config file writes.
---
--- Watches `*.lua`, `*.vim`, `*.toml`, `*.ts`, and vimrc files under
--- `$NVIM_CONFIG_HOME`. Intended to call `dpp#check_files` and
--- `dpp#make_state` when configs change (not yet wired up).
---@param args {cache_home: string,cache_github:string, dpp_script: string}
---@return boolean true if setup finished successfully.
local function setup_autocmd_load_state_succeeded(args)
  local dpp_cache_home = args.cache_home
  local dpp_cache_github = args.cache_github
  local dpp_denops_script = args.dpp_script
  if
    dpp_cache_home == nil
    or dpp_cache_github == nil
    or dpp_denops_script == nil
  then
    vim.notify('[VIMRC#BOOTLOADER#AutoCmd]: invalid args', vim.log.levels.ERROR)
    return false
  else
    -- When BufWritePost, check buf is config files,
    -- and update plugins and dpp cache if so.
    vim.api.nvim_create_autocmd('BufWritePost', { -- {{{
      pattern = '*.lua,*.vim,*.toml,*.ts,vimrc,.vimrc',
      group = my_autocmds,
      callback = function(ev)
        local filepath = vim.api.nvim_buf_get_name(ev.buf)
        if is_under_nvim_config_home(filepath) then
          if filepath:match('%.toml$') then
            -- TOML file: full update (install plugins, update, make_state)
            vim.notify(
              '[VIMRC#BOOTLOADER#AutoCmd]: TOML config updated, full dpp update',
              vim.log.levels.WARN
            )
            return require('bootloader/dpp/auto_update').dpp_update({
              cache_home = dpp_cache_home,
              cache_github = dpp_cache_github,
              dpp_script = dpp_denops_script,
            }, false)
          else
            -- Non-TOML file: only rebuild state (skip install/update)
            vim.notify(
              '[VIMRC#BOOTLOADER#AutoCmd]: Config updated, rebuilding state',
              vim.log.levels.WARN
            )
            return require('bootloader/dpp/make_state').run({
              cache_home = dpp_cache_home,
              cache_github = dpp_cache_github,
              dpp_script = dpp_denops_script,
            })
          end
        else
          -- Skip if buf is not the config file's one
          return true
        end
      end,
    }) -- }}}
    -- Create custom Command to force update {{{
    vim.api.nvim_create_user_command('DppUpdate', function()
      require('bootloader/dpp/auto_update').dpp_update({
        cache_home = dpp_cache_home,
        cache_github = dpp_cache_github,
        dpp_script = dpp_denops_script,
      }, true)
    end, {
      desc = 'Rebuild dpp plugin state manually',
    })
    -- }}}
    return true
  end
end

M.setup_autocmd_make_state_post = setup_autocmd_make_state_post
M.setup_autocmd_load_state_succeeded = setup_autocmd_load_state_succeeded
M.setup_autocmd_load_state_failed = setup_autocmd_load_state_failed
return M

