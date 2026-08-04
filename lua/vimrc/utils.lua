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

-- Get the default background color of the current colorscheme.
-- Returns `nil` when it cannot be resolved.
local function get_default_background()
  local colors_name = vim.g.colors_name or ''

  if colors_name:match('^catppuccin') then
    -- catppuccin: `palette.base` is the default background
    local ok, palettes = pcall(require, 'catppuccin.palettes')
    if ok then
      return palettes.get_palette(vim.g.catppuccin_flavour).base
    end
  elseif colors_name:match('^tokyonight') then
    -- tokyonight: `colors.bg` is the default background
    -- Use the style of the active colorscheme (e.g. `night` of
    -- `tokyonight-night`), not the configured default style.
    local ok, colors = pcall(require, 'tokyonight.colors')
    if ok then
      local style = colors_name:match('^tokyonight%-(.+)$')
      local opts = style and { style = style }
        or require('tokyonight.config').options
      return colors.setup(opts).bg
    end
  elseif colors_name:match('^nightfox') then
    -- nightfox: `palette.bg1` is the default background (`bg0` is for
    -- statusline and floats)
    local ok, palettes = pcall(require, 'nightfox.palette')
    if ok then
      return palettes.load(vim.g.nightfox_style or 'nightfox').bg1
    end
  end

  return nil
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
  local bg = get_default_background()
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

return M
