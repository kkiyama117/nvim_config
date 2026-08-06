-- ==========================================================================
-- BoilerPlate for colorscheme
-- ==========================================================================
-- For Switching colorscheme easily, set dummy variables
-- They should be updated when colorscheme is loaded.
vim.g['vimrc#colors'] = {}
vim.g['vimrc#color_bg'] = nil

-- Get the default background color of the current colorscheme.
-- Returns `nil` when it cannot be resolved.
local function get_default_background()
  return vim.g['vimrc#color_bg']
end

