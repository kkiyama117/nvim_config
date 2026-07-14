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
-- functions
-- ========================================================================== 
local patch = vim.fn['ddc#custom#patch_global']
-- we should set `ui`, `sources`, `completionMenu`
patch('ui', 'native')
patch('sources', { 'around' })
patch('sourceOptions', {
  -- default settings
  _ = {
    matchers = { 'matcher_head' },
    sorters = { 'sorter_rank' },
    -- converters
  },
  around  = { mark = '[A]' }
})
patch('sourceParams', {
  around = { maxSize = 500 },
})

-- ========================================================================== 
-- KEYBINDS
-- ========================================================================== 
-- 
--inoremap <Tab>   <Cmd>call pum#map#insert_relative(+1)<CR>
--inoremap <S-Tab> <Cmd>call pum#map#insert_relative(-1)<CR>
--inoremap <C-n>   <Cmd>call pum#map#insert_relative(+1)<CR>
--inoremap <C-p>   <Cmd>call pum#map#insert_relative(-1)<CR>
--inoremap <C-y>   <Cmd>call pum#map#confirm()<CR>
--inoremap <C-e>   <Cmd>call pum#map#cancel()<CR>

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
	  --
  -- }
})
-- }}}

