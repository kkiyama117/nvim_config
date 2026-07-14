-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.
-- }}}

-- lua_source {{{
local patch = vim.fn['ddc#custom#patch_global']

patch('ui', 'native')
patch('sources', { 'around' })
patch('sourceOptions', {
  _ = {
    matchers = { 'matcher_head' },
    sorters = { 'sorter_rank' },
  },
})
patch('sourceParams', {
  around = { maxSize = 500 },
})

-- Enable ddc (registers the denops plugin + autocmds).  Without this,
-- patch_global() only stores config and no completion fires.
vim.fn['ddc#enable']()
-- }}}

