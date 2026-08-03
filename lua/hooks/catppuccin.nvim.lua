-- lua_add {{{
--
-- }}}

-- lua_source {{{
require('catppuccin').setup({
  --flavour = 'auto', -- `macchiato`, `mocha` etc.
  flavour = 'mocha', -- `macchiato`, `mocha` etc.
  background = {
    light = 'latte',
    dark = 'macchiato',
  },
  transparent_background = true,
  float = {
    transparent = true,
    --solid = true, -- check |winboader|
  },
  term_colors = true,
  dim_inactive = {
    enabled = true,
    shade = 'dark',
    percentage = 0.3,
  },
  lsp_styles = { -- Handles the style of specific lsp hl groups (see `:h lsp-highlight`).
    virtual_text = {
      errors = { 'italic' },
      hints = { 'italic' },
      warnings = { 'italic' },
      information = { 'italic' },
      ok = { 'italic' },
    },
    underlines = {
      errors = { 'underline' },
      hints = { 'underline' },
      warnings = { 'underline' },
      information = { 'underline' },
      ok = { 'underline' },
    },
    inlay_hints = {
      background = true,
    },
  },
  --auto_integrations = true,
  integrations = {
    aerial = true,
    --dap = true,
    --dap_ui = true,
    --dropbar= {enabled=false,color_mode=false}
    gitsigns = true,
    mason = true,
    --noise = true,
    notify = true,
    sandwich = true,
    which_key = true,
  },
  highlight_overrides = {
    all = function(colors)
      return {
        Normal = { fg = colors.text, bg = 'NONE' },
        --NonText = { fg = colors.text, bg = 'NONE' },
        -- transparent others
        NormalNC = { fg = colors.text, bg = 'NONE' },
        --NormalSB = { fg = colors.text, bg = 'NONE' },
      }
    end,
  },
})

vim.cmd([[colorscheme catppuccin-nvim]])

-- }}}

