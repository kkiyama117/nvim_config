-- lua_source {{{
-- Translated from Shougo's reference config:
-- https://github.com/Shougo/shougo-s-github/blob/b10f7172e39731a1e54f086258b5c6a6ac055aa6/vim/rc/ddc.toml#L10

vim.fn['pum#set_option']({
  auto_confirm_time = 0,
  auto_select = false,
  blend = 20,
  border = 'none',
  commit_characters = { '.' },
  highlight_scrollbar = 'None',
  insert_preview = true,
  max_height = 5,
  max_width = 80,
  offset_cmdcol = 0,
  padding = false,
  preview = true,
  preview_remains = true,
  preview_width = 80,
  reversed = false,
  use_setline = not vim.fn.has('nvim'),
})

-- vim.fn['pum#set_local_option']('c', {
--   horizontal_menu = false,
-- })

-- NOTE: For horizontal_menu
vim.fn['pum#set_option']({
  follow_cursor = false,
  horizontal_menu = false,
  max_horizontal_items = 2,
})

-- }}}

