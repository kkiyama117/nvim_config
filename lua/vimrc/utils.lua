-- VIMRC MODULE (to define functions)
local M = {}
-- TODO: Add `on_filetype()` function

-- Toggle option function (with mapping in `lua/mappings.lua`){{{
function M.toggle_option(name)
  if name == 'laststatus' then
    local cur = vim.opt_local.laststatus:get()
    vim.opt_local.laststatus = cur == 0 and 2 or 0
  else
    vim.opt_local[name] = not vim.opt_local[name]:get()
  end
  vim.notify(
    string.format('%s=%s', name, vim.inspect(vim.opt_local[name]:get())),
    vim.log.levels.INFO
  )
end

function M.toggle_conceal()
  local cur = vim.opt_local.conceallevel:get()
  vim.opt_local.conceallevel = cur == 0 and 3 or 0
  vim.notify(
    string.format(
      'conceallevel=%s',
      vim.inspect(vim.opt_local.conceallevel:get())
    ),
    vim.log.levels.INFO
  )
end
-- }}}

-- Toggle background color function (with mapping in `lua/mappings.lua`){{{
-- Highlight groups whose background is toggled between `NONE` (transparent)
-- and the colorscheme default background color.
local transparent_groups = {
  'Normal',
  'NormalNC',
  'SignColumn',
  'SignColumnSB',
  'LineNr',
  'LineNrAbove',
  'LineNrBelow',
  'CursorLineNr',
  'EndOfBuffer',
  'FoldColumn',
  'Folded',
  'FloatBorder',
  'NormalFloat',
  'MsgArea',
}

-- Saved background colors when transparency is enabled.
-- key: highlight group name, value: original background color
local saved_backgrounds = {}

local function get_background(group)
  return vim.api.nvim_get_hl(0, { name = group }).bg
end

-- Set background color with keeping the foreground color to avoid breaking
-- the visual when the group is linked to another group.
local function set_background(group, bg)
  local hl = vim.api.nvim_get_hl(0, { name = group })
  vim.api.nvim_set_hl(0, group, { fg = hl.fg, bg = bg })
end

function M.is_background_transparent()
  local bg = get_background('Normal')
  return bg == nil or bg == 'NONE'
end

function M.background_transparent()
  saved_backgrounds = {}
  for _, group in ipairs(transparent_groups) do
    local bg = get_background(group)
    if bg ~= nil and bg ~= 'NONE' then
      saved_backgrounds[group] = bg
    end
    set_background(group, 'NONE')
  end
  vim.notify('background=NONE (transparent)', vim.log.levels.INFO)
end

function M.background_opaque()
  -- Restore the previous background colors if exists
  if next(saved_backgrounds) ~= nil then
    for group, bg in pairs(saved_backgrounds) do
      set_background(group, bg)
    end
    saved_backgrounds = {}
    vim.notify('background=restored', vim.log.levels.INFO)
    return
  end

  -- Use the default background color of the colorscheme
  local bg = vim.g['vimrc#color_bg']
  if bg == nil then
    -- Fallback: re-source the colorscheme to restore its defaults
    local colors_name = vim.g.colors_name
    if colors_name == nil then
      vim.notify(
        'Cannot resolve the default background color',
        vim.log.levels.WARN
      )
      return
    end
    vim.cmd('colorscheme ' .. colors_name)
    vim.notify(
      'background=colorscheme default (resourced)',
      vim.log.levels.INFO
    )
    return
  end

  for _, group in ipairs(transparent_groups) do
    set_background(group, bg)
  end
  vim.notify(string.format('background=%s', bg), vim.log.levels.INFO)
end

function M.toggle_background()
  if M.is_background_transparent() then
    M.background_opaque()
  else
    M.background_transparent()
  end
end
-- }}}

-- Diag location list{{{
function M.diagnostics_to_location_list()
  if not vim.fn.has('nvim') then
    return
  end

  local current = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
  local qflist = vim
    .iter(vim.diagnostic.get())
    :filter(function(d)
      local bufname = vim.fn.bufname(d.bufnr)
      return vim.fn.fnamemodify(bufname, ':p') == current
    end)
    :map(function(d)
      return {
        bufnr = d.bufnr,
        lnum = d.lnum + 1,
        col = d.col + 1,
        text = d.message,
      }
    end)
    :totable()

  if vim.tbl_isempty(qflist) then
    vim.notify('LSP Quick fix is empty', vim.log.levels.INFO)
    vim.cmd('lclose')
  else
    vim.fn.setloclist(vim.fn.win_getid(), qflist)
    vim.cmd('lopen')
  end
end
-- }}}

-- Append staged git diff as comments to current buffer{{{
function M.append_diff()
  local git_root = vim.fn.fnamemodify(vim.fn.finddir('.git', '.;'), ':h')
  if git_root == '' then
    return
  end

  local diff =
    vim.fn.system('git -C ' .. vim.fn.shellescape(git_root) .. ' diff --cached')
  if diff == '' then
    return
  end

  local lines = vim.split(diff, '\n')
  -- Take first 200 lines and prefix with '# '
  local comment_lines = vim
    .iter(lines)
    :take(200)
    :map(function(line)
      return '# ' .. line
    end)
    :totable()

  vim.fn.append(vim.fn.line('$'), comment_lines)
end
-- }}}

-- Debug-mode notify tee {{{-- Wrap the current `vim.notify` so messages are also appended to
-- `notify.log` under `log_dir` (default: `$NVIM_CACHE_HOME/logs`).
-- Returns the wrapper; assign it to `vim.notify`.
-- In debug mode this is called twice:
--   1. `lua/vimrc/debug.lua` (early; wraps the default notify)
--   2. `lua/hooks/nvim-notify.dpp` (after `vim.notify = plugin`)
local function notify_level_name(level)
  for name, lv in pairs(vim.log.levels) do
    if lv == level then
      return name
    end
  end
  return tostring(level)
end

function M.wrap_notify_with_log(log_dir)
  local orig_notify = vim.notify
  return function(msg, level, opts)
    if vim.in_fast_event() then
      vim.schedule(function()
        vim.notify(msg, level, opts)
      end)
      return
    end
    local line = string.format(
      '[%s][%s] %s',
      os.date('%H:%M:%S'),
      notify_level_name(level),
      tostring(msg)
    )
    vim.fn.writefile(
      { line },
      vim.fs.joinpath(
        log_dir or vim.fs.joinpath(vim.env.NVIM_CACHE_HOME, 'logs'),
        'notify.log'
      ),
      'a'
    )
    return orig_notify(msg, level, opts)
  end
end
-- }}}

return M

