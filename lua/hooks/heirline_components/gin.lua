-- Gin buffer source label (INDEX/HEAD/OURS/THEIRS/<commitish>/WORKTREE).
-- Ported from kyoh86/dotfiles
-- (nvim/lua/kyoh86/plug/heirline/gin_buffer_source.lua).

local gin_buffer_sources = require('hooks/heirline_components/gin_buffer_sources')

gin_buffer_sources.setup()

return {
  condition = function()
    return gin_buffer_sources.source_label() ~= nil
  end,
  provider = function()
    return " " .. gin_buffer_sources.source_label() .. " "
  end,
  hl = { bold = true, bg = "diag_warn", fg = "black" },
}
