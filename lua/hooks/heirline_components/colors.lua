-- It converts each colors from colorscheme to common interface

local M = {}

local function convert_colors(colorscheme_name, colors)
  local result = {}
  if colorscheme_name == 'catppuccin' then
    -- Merge the catppuccin palette with our common interface colors.
    -- NOTE: catppuccin has no `orange`; the closest is `peach`.
    -- HERE
    result.colors = vim.tbl_extend('force', colors, {
      bright_bg = colors.base,
      bright_fg = colors.text,
      dark_red = colors.maroon,
      gray = colors.overlay1,
      purple = colors.mauve,
      cyan = colors.teal,
      orange = colors.peach,
      diag_warn = colors.yellow,
      diag_error = colors.red,
      diag_hint = colors.teal,
      diag_info = colors.blue,
      git_del = colors.red,
      git_add = colors.green,
      git_change = colors.yellow,
    })
  else
    -- UNKNOWN COLORS
    local utils = require('heirline.utils')
    -- HERE ARE COLORS USED IN OUR CONFIG
    -- NOTE: get_highlight() may return nil (e.g. `diffDeleted` is not set by
    -- some schemes); fall back to catppuccin-mocha defaults in that case.
    local colors = {
      bright_bg = utils.get_highlight('Folded').bg or '#1e1e2e',
      bright_fg = utils.get_highlight('Folded').fg or '#cdd6f4',
      red = utils.get_highlight('DiagnosticError').fg or '#f38ba8',
      dark_red = utils.get_highlight('DiffDelete').bg or '#eba0ac',
      green = utils.get_highlight('String').fg or '#a6e3a1',
      blue = utils.get_highlight('Function').fg or '#89b4fa',
      gray = utils.get_highlight('NonText').fg or '#7f849c',
      orange = utils.get_highlight('Constant').fg or '#fab387',
      purple = utils.get_highlight('Statement').fg or '#cba6f7',
      cyan = utils.get_highlight('Special').fg or '#94e2d5',
      diag_warn = utils.get_highlight('DiagnosticWarn').fg or '#f9e2af',
      diag_error = utils.get_highlight('DiagnosticError').fg or '#f38ba8',
      diag_hint = utils.get_highlight('DiagnosticHint').fg or '#94e2d5',
      diag_info = utils.get_highlight('DiagnosticInfo').fg or '#89b4fa',
      git_del = utils.get_highlight('diffDeleted').fg or '#f38ba8',
      git_add = utils.get_highlight('diffAdded').fg or '#a6e3a1',
      git_change = utils.get_highlight('diffChanged').fg or '#f9e2af',
    }
    result.colors = colors
  end
  return result
end

M.setup = convert_colors

return M

