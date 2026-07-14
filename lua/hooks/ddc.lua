-- lua_add {{{
-- Plugin functions cannot be called here (the plugin is not sourced yet).
-- Only mappings and global options.

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

local function commandline_post()
  if vim.b.prev_buffer_config ~= nil then
    vim.fn['ddc#custom#set_buffer'](vim.b.prev_buffer_config)
    vim.b.prev_buffer_config = nil
  end
end

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

-- nnoremap ;;  <Cmd>call cmdline#enable()<CR><Cmd>call CommandlinePre(':')<CR>:
vim.keymap.set('n', ';;', function()
  vim.cmd('call cmdline#enable()')
  commandline_pre(':')
  vim.api.nvim_feedkeys(':', 'n', false)
end, { desc = 'Cmdline enable + pre-processing' })

-- nnoremap ;  <Nop>
vim.keymap.set('n', ';', '<Nop>', { desc = 'Disable ;' })
-- }}}

-- lua_source {{{
local patch = vim.fn['ddc#custom#patch_global']

patch('ui', 'native')
patch('sources', { 'around' })
patch('sourceOptions', {
  -- default settings
  _ = {
    matchers = { 'matcher_head' },
    sorters = { 'sorter_rank' },
  },
  around  = { mark = '[A]' }
})
patch('sourceParams', {
  around = { maxSize = 500 },
})

-- Enable ddc (registers the denops plugin + autocmds).  Without this,
-- patch_global() only stores config and no completion fires.
vim.fn['ddc#enable']()
-- }}}
