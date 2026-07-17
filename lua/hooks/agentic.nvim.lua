-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.
vim.keymap.set('n', '<Space>a', function()
  require('agentic').new_session()
end, { desc = 'agentic: new session' })
-- }}}

-- lua_source {{{
require("agentic").setup({
     provider = "pi-acp", 
     --provider = "claude-agent-acp",
     acp_providers = {
       ["pi-acp"] = {
         command = "/home/kiyama/.local/share/mise/installs/npm-pi-acp/latest/bin/pi-acp",
       },
     },
     windows = {
       position = "right",
       width = "40%",
     },
   })
-- }}}

