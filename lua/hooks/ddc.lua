-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.
-- CommandLine settings for ddc
local function commandline_post()
  if vim.b.prev_buffer_config ~= nil then
    vim.fn['ddc#custom#set_buffer'](vim.b.prev_buffer_config)
    vim.b.prev_buffer_config = nil
  end
end

local function commandline_pre(mode)
  if vim.b.prev_buffer_config ~= nil then
    return
  end

  -- Overwrite sources
  vim.b.prev_buffer_config = vim.fn['ddc#custom#get_buffer']()

  if mode == ':' then
    vim.fn['ddc#custom#patch_buffer']('sourceOptions', {
      _ = {
        keywordPattern = '(~\\w+)?[0-9a-zA-Z_:#*/.-]*',
      },
    })

    -- Use zsh source for :! completion
    vim.fn['ddc#custom#set_context_buffer'](function()
      return vim.fn.stridx(vim.fn.getcmdline(), '!') == 0
          and { cmdlineSources = {
            'around',
	    -- TODO: install each ddc plugins
            --'shell_native', 'cmdline', 'cmdline_history', 'around',
          } }
          or {}
    end)
  end

  vim.api.nvim_create_autocmd('User', {
    pattern = 'DDCCmdlineLeave',
    group = 'MyAutoCmd',
    once = true,
    callback = commandline_post,
  })

  vim.fn['ddc#enable_cmdline_completion']()
end

-- ========================================================================== 
-- KEYBINDS
-- ========================================================================== 
-- nnoremap :  <Cmd>call CommandlinePre(':')<CR>:
vim.keymap.set('n', ':', function()
  commandline_pre(':')
  vim.api.nvim_feedkeys(':', 'n', false)
end, { desc = 'Cmdline with pre-processing' })

-- nnoremap ?  <Cmd>call CommandlinePre('/')<CR>?
vim.keymap.set('n', '?', function()
  commandline_pre('/')
  vim.api.nvim_feedkeys('?', 'n', false)
end, { desc = 'Search with pre-processing' })

-- xnoremap :  <Cmd>call CommandlinePre(':')<CR>:
vim.keymap.set('x', ':', function()
  commandline_pre(':')
  vim.api.nvim_feedkeys(':', 'n', false)
end, { desc = 'Cmdline with pre-processing (visual)' })

-- nnoremap ;;  <Cmd>call CommandlinePre(':')<CR>:
vim.keymap.set('n', ';;', function()
  -- TODO: make `cmdline#enable`
  -- vim.cmd('call cmdline#enable()')
  commandline_pre(':')
  vim.api.nvim_feedkeys(':', 'n', false)
end, { desc = 'Cmdline enable + pre-processing' })

-- nnoremap ;  <Nop>
vim.keymap.set('n', ';', '<Nop>', { desc = 'Disable ;' })
-- }}}

-- lua_source {{{
vim.fn["ddc#custom#load_config"](vim.env.NVIM_CONFIG_HOME .. "/denops/ddc.ts") 
-- ========================================================================== 
-- KEYBINDS
-- ========================================================================== 
-- Keys may sorted alphabetally.
-- -----------------------------------------------
-- FOR INSERT MODE COMPLETION -----------------------------------------------
-- Config to use `pum.vim`; If you use `native-ui`, use `pumvisible`
vim.keymap.set('i', '<TAB>', function()
  if vim.fn['ddc#ui#inline#visible']() == 1 then
    return vim.fn['ddc#map#insert_item'](0)
  elseif vim.fn['pum#visible']() == 1 then
    return vim.fn['pum#map#insert_relative'](1, 'empty')
  elseif vim.fn.col('.') <= 1 then
    return '<TAB>'
  elseif vim.fn.getline('.'):sub(vim.fn.col('.') - 1, vim.fn.col('.') - 1):match('%s') then
    return '<TAB>'
  else
    return vim.fn['ddc#map#manual_complete']()
  end
end, { expr = true })
vim.keymap.set('i', '<S-Tab>', function()
  vim.fn['pum#map#insert_relative'](-1)
end,{})
vim.keymap.set('i', '<C-e>', function() if vim.fn['ddc#map#can_complete']() == 1 then
    return vim.fn['ddc#map#insert_item'](0)
  else
    return '<End>'
  end
end, { expr = true })
vim.keymap.set('i', '<C-g>', function()
  return vim.fn['pum#map#toggle_preview']()
end, {desc = "No `expr`"})
vim.keymap.set('i', '<C-g>', function()
  return vim.fn['pum#map#insert_item'](0)
end, { expr = true, desc = "with `expr`"})
vim.keymap.set('i', '<C-l>', function()
  return vim.fn['ddc#map#manual_complete']()
end, { expr = true })
vim.keymap.set('i', '<C-n>', function()
  vim.fn['pum#map#select_relative'](1)
end)
vim.keymap.set('i', '<C-o>', function()
  vim.fn['pum#map#confirm_matched_pattern']('^\\S\\+')
end)
vim.keymap.set('i', '<C-p>', function()
  vim.fn['pum#map#select_relative'](-1)
end)
vim.keymap.set('i', '<C-y>', function()
  vim.fn['pum#map#confirm_suffix']()
end)

-- FOR COMMAND-LINE MODE COMPLETION -----------------------------------------
vim.keymap.set('c', '<Tab>', function()
  if vim.fn['ddc#ui#inline#visible']() == 1 then
    return vim.fn['ddc#map#insert_item'](0)
  elseif vim.fn.wildmenumode() == 1 then
    return vim.fn.nr2char(vim.o.wildcharm)
  elseif vim.fn['pum#visible']() == 1 then
    return vim.fn['pum#map#insert_relative'](1)
  else
    return vim.fn['ddc#map#manual_complete']()
  end
end, { expr = true })
vim.keymap.set('c', '<S-Tab>', function()
  vim.fn['pum#map#insert_relative'](-1)
end)
vim.keymap.set('c', '<C-e>', function()
  if vim.fn['ddc#ui#inline#visible']() == 1 then
    return vim.fn['ddc#map#insert_item'](0)
  elseif vim.fn['pum#visible']() == 1 then
    return vim.fn['pum#map#cancel']()
  else
    return '<End>'
  end
end, { expr = true })
vim.keymap.set('c', '<C-g>', function()
  return vim.fn['pum#map#insert_item'](0)
end, { expr = true })
vim.keymap.set('c', '<C-o>', function()
  vim.fn['pum#map#confirm']()
end)
vim.keymap.set('c', '<C-q>', function()
  vim.fn['pum#map#select_relative'](1)
end)
vim.keymap.set('c', '<C-y>', function()
  vim.fn['pum#map#confirm']()
end)
vim.keymap.set('c', '<C-z>', function()
  vim.fn['pum#map#select_relative'](-1)
end)

-- FOR TERMINAL MODE COMPLETION ---------------------------------------------
-- Mouse Support ------------------------------------------------------------
vim.keymap.set({'i','c','t'}, '<LeftMouse>', function()
  vim.fn['pum#map#confirm_mouse']()
end, { desc = 'Left Mouse with pum.vim' })
vim.keymap.set({'i','c','t'}, '<RightMouse>', function()
  vim.fn['pum#map#select_mouse']()
end, { desc = 'Right Mouse with pum.vim' })

-- ========================================================================== 

-- Enable ddc (registers the denops plugin + autocmds).  Without this,
-- patch_global() only stores config and no completion fires.
--vim.fn['ddc#enable_terminal_completion']()
vim.fn['ddc#enable']({
  -- context_filetype = {
  -- }
})
-- }}}

