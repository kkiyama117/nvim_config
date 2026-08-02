--- Fallback router for bootloader error conditions.
---
--- Dispatches to `bootloader/min` rescue routines based on `error_number`:
--- - **F1**: `dpp#min#load_state` failed → delegate to `bootloader/dpp`
--- - **F2**: `dpp#min#load_state` missing → `rescue_min`
--- - **F3**: normal dpp deps missing → `rescue_normal`
local M = {}

--- Handle a bootloader failure by running the appropriate rescue path.
---@param args {error_number: integer, extra_args:TODO}
---@return boolean|nil `true`/`false` from rescue on F2/F3; `nil` on unknown error
M.startup = function(args)
  local error_number = args.error_number
  local extra_args = args.extra_args
  vim.notify(
    ('[BOOTLOADER]: Fallback called with Error %s'):format(error_number),
    vim.log.levels.ERROR
  )
  -- F1: failed to load state => check plugins status, then make_state
  -- F2: dpp#min#load_state isn't found
  -- F3: plugins for dpp aren't found
  if error_number == 1 then
    local cache_home = extra_args.cache_home
    local cache_github = extra_args.cache_github
    local dpp_script = extra_args.dpp_script
    -- TODO: ask user to run dpp/auto_update
    require('bootloader/dpp/auto_update').dpp_update_force({
      cache_home = cache_home,
      cache_github = cache_github,
      dpp_script = dpp_script,
    })
  elseif error_number == 2 then
    -- F2-> EXTRA_ARGS= {missing_plugins}
    local missing_plugins = extra_args.missing_plugins
    vim.notify(
      ('[BOOTLOADER/Fallback]: rescue %s'):format(error_number),
      vim.log.levels.ERROR
    )
    -- This may call `:restart`
    if missing_plugins then
      return require('bootloader/min').rescue_min(missing_plugins)
    else
      vim.notify(
        '[BOOTLOADER/Fallback]: rescue called but no missing_plugins',
        vim.log.levels.ERROR
      )
      return false
    end
  elseif error_number == 3 then
    -- F2-> EXTRA_ARGS= {missing_plugins}
    local missing_plugins = extra_args.missing_plugins
    if missing_plugins then
      vim.notify(
        ('[BOOTLOADER/Fallback]: rescue %s'):format(error_number),
        vim.log.levels.ERROR
      )
      return require('bootloader/min').rescue_normal(missing_plugins)
    else
      vim.notify(
        '[BOOTLOADER/Fallback]: rescue called but no missing_plugins',
        vim.log.levels.ERROR
      )
      return false
    end
  else
    vim.notify(
      ('[BOOTLOADER/Fallback]: UNKNOWN ERROR OF BOOTLOADER'):format(
        error_number
      ),
      vim.log.levels.ERROR
    )
  end
end

return M

