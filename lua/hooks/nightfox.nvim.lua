-- lua_add {{{
-- }}}

-- lua_source {{{
require('nightfox').setup({
  options = {
    compile_path = vim.fn.expand(
      vim.fs.joinpath(vim.env.NVIM_CACHE_HOME, 'nightfox')
    ),
    transparent = true,
    --dim_inactive = true,
  },
})

-- vim.cmd([[colorscheme nightfox]])

-- }}}

