--- Main bootloader entry point for dpp.vim.
---
--- Sets dpp cache paths, prepends minimum dependencies to runtimepath, and
--- attempts to load a compiled dpp state.
--- On succeeded, delegates to `$NVIM_CONFIG_HOME/lua/hooks/dpp.vim.lua`.
--- On failure, delegates to `bootloader/normal` or `bootloader/fallback` as appropriate.
local M = {}

local is_debug = vim.g['vimrc#is_debug']

--- Set global variables consumed by dpp.vim and dpp-ext plugins.
---
--- Configures `vimrc#dpp#*` paths (cache, GitHub clone dir, local dir,
--- denops script) and the minimum dependency list. Values must stay in sync
--- with the dpp-ext plugin configuration.
local function set_dpp_global_value() -- {{{
  vim.g['vimrc#dpp#minimum_deps'] = {
    'Shougo/dpp.vim',
    'Shougo/dpp-ext-lazy',
    'vim-denops/denops.vim',
  }
  -- vim.g.dpp_cache_home = vim.fs.joinpath(vim.g.xdg_cache_home, "dpp")
  vim.g['vimrc#dpp#cache_home'] =
    vim.fs.joinpath(vim.env.NVIM_CACHE_HOME, 'dpp')
  vim.g['vimrc#dpp#cache_github'] =
    vim.fs.joinpath(vim.g['vimrc#dpp#cache_home'], 'repos', 'github.com')
  vim.g['vimrc#dpp#cache_local'] =
    vim.fs.joinpath(vim.g['vimrc#dpp#cache_home'], 'local')
  vim.g['vimrc#dpp#denops_script'] =
    vim.fs.joinpath(vim.env.NVIM_CONFIG_HOME, 'denops', 'dpp.ts')
  if is_debug then -- {{{
    vim.notify(
      ('[VIMRC#BOOTLOADER]: dpp#cache_home = %s'):format(
        vim.g['vimrc#dpp#cache_home']
      ),
      vim.log.levels.DEBUG
    )
    vim.notify(
      ('[VIMRC#BOOTLOADER]: dpp#cache_github = %s'):format(
        vim.g['vimrc#dpp#cache_github']
      ),
      vim.log.levels.DEBUG
    )
    vim.notify(
      ('[VIMRC#BOOTLOADER]: dpp#cache_local = %s'):format(
        vim.g['vimrc#dpp#cache_local']
      ),
      vim.log.levels.DEBUG
    )
    vim.notify(
      ('[VIMRC#BOOTLOADER]: dpp#denops_script= %s'):format(
        vim.g['vimrc#dpp#denops_script']
      ),
      vim.log.levels.DEBUG
    )
  end -- }}}
end -- }}}

--- Run the primary dpp startup sequence.
---
--- 1. Set dpp global variables.
--- 2. Prepend minimum deps (`dpp.vim`, `dpp-ext-lazy`, `denops.vim`) to runtimepath.
--- 3. Call `dpp#min#load_state`; on success trigger auto-update setup,
---    on non-zero result rebuild state via `bootloader/normal.make_state`,
---    on missing function fall back to `bootloader/fallback`.
local function startup()
  -- 0: Set env variable
  set_dpp_global_value()
  -- 1: Add minimum_deps to rtp
  for _, repo in ipairs(vim.g['vimrc#dpp#minimum_deps']) do
    vim.opt.runtimepath:prepend(
      vim.fs.joinpath(vim.g['vimrc#dpp#cache_github'], repo)
    )
    if is_debug then
      vim.notify(
        ('[VIMRC#BOOTLOADER]: rtp:prepend %s'):format(repo),
        vim.log.levels.DEBUG
      )
    end
  end
  -- 2: Call dpp#load_state;
  --    `dpp.vim` COMPILE the vimrc and load it from the cache dir.
  --    This process doesn't depend on `denops.vim`; so we don't need to load it here.
  local ok, result =
    pcall(vim.fn['dpp#min#load_state'], vim.g['vimrc#dpp#cache_home'])
  if ok then
    if result == 0 then
      -- When Succeeded, set AutoCmds that is hooked by configuration files updated
      require('bootloader/autocmds').setup_autocmd_load_state_succeeded({
        cache_home = vim.g['vimrc#dpp#cache_home'],
        cache_github = vim.g['vimrc#dpp#cache_github'],
        dpp_script = vim.g['vimrc#dpp#denops_script'],
      })
      require('bootloader/autocmds').setup_autocmd_make_state_post()
      if is_debug then
        vim.notify(
          '[VIMRC#BOOTLOADER]: call dpp#min#load_state successfully',
          vim.log.levels.INFO
        )
      end
      return true
    else
      -- F1: `dpp#load_state` returned non-zero value (state is broken); call `dpp#make_state`
      vim.notify(
        '[VIMRC#BOOTLOADER]: call dpp#min#load_state failed.',
        vim.log.levels.WARN
      )
      -- we should load denops manually to call dpp#make_state; `--noplugin` is set.
      if vim.fn.has('nvim') == 1 then
        local denops_path = vim.fs.joinpath(
          vim.g['vimrc#dpp#cache_github'],
          'vim-denops',
          'denops.vim'
        )
        -- Ensure denops.vim is installed before trying to load it.
        -- Without it, DenopsReady never fires and the F1 recovery chain
        -- dead-ends: make_state (and its F3 fallback) is never reached.
        if vim.fn.isdirectory(denops_path) == 0 then
          vim.notify(
            '[VIMRC#BOOTLOADER]: denops.vim not found, installing...',
            vim.log.levels.WARN
          )
          require('bootloader/min/github_installer').install_from_remote({
            repo = 'https://github.com/vim-denops/denops.vim',
            dest = denops_path,
          })
        end
        vim.opt.runtimepath:prepend(denops_path)
        vim.cmd([[runtime! plugin/denops.vim]])
      end
      require('bootloader/autocmds').setup_autocmd_load_state_failed({
        cache_home = vim.g['vimrc#dpp#cache_home'],
        cache_github = vim.g['vimrc#dpp#cache_github'],
        dpp_script = vim.g['vimrc#dpp#denops_script'],
      })
      -- In headless mode, setup_autocmd_load_state_failed skips the
      -- DenopsReady autocord (no UI to avoid racing interactive sessions).
      -- But if this is the only session, the state would never be rebuilt.
      -- Start denops and call make_state directly instead.
      if #vim.api.nvim_list_uis() == 0 then
        vim.notify(
          '[VIMRC#BOOTLOADER]: headless session, starting denops directly...',
          vim.log.levels.WARN
        )
        vim.fn['denops#server#start']()
        vim.wait(15000, function()
          return vim.fn['denops#server#status']() == 'running'
        end)
        if vim.fn['denops#server#status']() == 'running' then
          vim.notify(
            '[VIMRC#BOOTLOADER]: denops ready, calling make_state...',
            vim.log.levels.WARN
          )
          require('bootloader/dpp/make_state').run({
            cache_home = vim.g['vimrc#dpp#cache_home'],
            cache_github = vim.g['vimrc#dpp#cache_github'],
            dpp_script = vim.g['vimrc#dpp#denops_script'],
          })
          -- Register installer-completion listener BEFORE waiting, so we
          -- don't miss the Dpp:ext:installer:updateDone event.
          local install_done = false
          vim.api.nvim_create_autocmd('User', {
            pattern = 'Dpp:ext:installer:updateDone',
            group = vim.api.nvim_create_augroup(
              'vimrc_boot_install',
              { clear = true }
            ),
            once = true,
            callback = function()
              install_done = true
            end,
          })
          -- Wait for state files to be written (async make_state completion)
          local state_file = vim.fs.joinpath(
            vim.g['vimrc#dpp#cache_home'],
            'nvim',
            'state.vim'
          )
          vim.wait(60000, function()
            return vim.fn.filereadable(state_file) == 1
          end)
          if vim.fn.filereadable(state_file) == 1 then
            vim.notify(
              '[VIMRC#BOOTLOADER]: state rebuilt successfully',
              vim.log.levels.INFO
            )
            -- Dpp:makeStatePost has fired and on_make_state_post triggered
            -- the async installer for user plugins. Wait for it to finish.
            local has_pending = false
            pcall(function()
              has_pending =
                #vim.fn['dpp#sync_ext_action'](
                  'installer',
                  'getNotInstalled',
                  vim.empty_dict()
                ) > 0
            end)
            if has_pending then
              vim.notify(
                '[VIMRC#BOOTLOADER]: waiting for plugin install...',
                vim.log.levels.WARN
              )
              vim.wait(120000, function()
                return install_done
              end)
              vim.notify(
                '[VIMRC#BOOTLOADER]: plugin install complete',
                vim.log.levels.INFO
              )
            end
          end
        end
      end
      require('bootloader/autocmds').setup_autocmd_make_state_post()
      vim.notify(
        '[VIMRC#BOOTLOADER]: set AutoCmds for recover',
        vim.log.levels.INFO
      )
      return false
    end
  else
    -- F2: dpp#min#load_state function not found etc (E117); Fallback
    vim.notify(
      '[VIMRC#BOOTLOADER]: call dpp#min#load_state is missing',
      vim.log.levels.ERROR
    )
    require('bootloader/fallback').startup({
      error_number = 2,
      missing_plugins = vim.g['vimrc#dpp#minimum_deps'],
    })
    require('bootloader/autocmds').setup_autocmd_make_state_post()
    return false
  end
end

M.startup = startup
return M

