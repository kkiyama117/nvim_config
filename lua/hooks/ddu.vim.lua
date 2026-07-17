-- lua_add {{{
-- ========================================================================== 
-- KEYMAPS
-- ========================================================================== 
-- Keymaps that are common between each `ui`; Opening each UI etc.
-- TODO: Update keymaps to use `LEADER` key
-- }}}

-- lua_source {{{
  vim.fn["ddu#custom#load_config"](vim.fn.stdpath("config") .. "/denops/ddu.ts")
-- }}}

