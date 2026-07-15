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
--vim.fn["ddc#custom#load_config"](vim.env.NVIM_CONFIG_HOME .. "/denops/ddc.ts") 
-- ========================================================================== 
-- functions
-- ========================================================================== 
local patch = vim.fn['ddc#custom#patch_global']
-- TODO: Move to `ddc.ts`
vim.fn['ddc#custom#patch_global']({
  --ui = 'native',
  ui = 'pum',
  -- autoCompleteEvents = {'CmdlineChanged'},
  -- cmdlineSources = {[':'] = { "shell-native" }},
  sources = { 'around' },
  sourceOptions = {
    -- default settings
    _ = {
      matchers = { 'matcher_head' },
      sorters = { 'sorter_rank' },
    },
    around = { mark = '[A]' },
  },
  sourceParams = {
    ["around"]  = { maxSize = 500 }
  },
})

-- ========================================================================== 
-- KEYBINDS
-- ========================================================================== 
-- 
--inoremap <Tab>   <Cmd>call pum#map#insert_relative(+1)<CR>
-- Config to use `pum.vim`; If you use `native-ui`, use `pumvisible`
vim.keymap.set('i', '<TAB>', function()
  if vim.fn['pum#visible']() == 1 then
    vim.fn['pum#map#insert_relative'](1)
    return ''
  end
  local col = vim.fn.col('.')
  if col <= 1 then
    return '<TAB>'
  end
  local char_before = vim.fn.getline('.'):sub(col - 1, col - 1)
  if char_before:match('%s') then
    return '<TAB>'
  end
  return vim.fn['ddc#map#manual_complete']()
end, { expr = true })

-- 
--inoremap <S-Tab> <Cmd>call pum#map#insert_relative(-1)<CR>
vim.keymap.set('i', '<S-Tab>', function()
  vim.fn['pum#map#insert_relative'](-1)
end,{})
--inoremap <C-n>   <Cmd>call pum#map#insert_relative(+1)<CR>
vim.keymap.set('i', '<C-n>', function()
  vim.fn['pum#map#select_relative'](1)
end,{})
--inoremap <C-p>   <Cmd>call pum#map#insert_relative(-1)<CR>
vim.keymap.set('i', '<C-p>', function()
  vim.fn['pum#map#select_relative'](-1)
end,{})
--inoremap <C-y>   <Cmd>call pum#map#confirm()<CR>
vim.keymap.set('i', '<C-y>', function()
  vim.fn['pum#map#confirm']()
end,{})
--inoremap <C-e>   <Cmd>call pum#map#cancel()<CR>
vim.keymap.set('i', '<C-e>', function()
  vim.fn['pum#map#cancel']()
end,{})

-- Mouse Support
vim.keymap.set({'i','c','t'}, '<LeftMouse>', function()
  vim.fn['pum#map#confirm_mouse']()
end, { desc = 'Left Mouse with pum.vim' })
vim.keymap.set({'i','c','t'}, '<RightMouse>', function()
  vim.fn['pum#map#select_mouse']()
end, { desc = 'Right Mouse with pum' })

-- Enable ddc (registers the denops plugin + autocmds).  Without this,
-- patch_global() only stores config and no completion fires.
--vim.fn['ddc#enable_terminal_completion']()
vim.fn['ddc#enable']({
  -- context_filetype = {
  -- }
})
-- }}}

