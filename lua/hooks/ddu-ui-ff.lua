-- lua_add {{{

-- ==========================================================================
-- KEYMAPS
-- ==========================================================================
local ff_group = vim.api.nvim_create_augroup('ddu-ui-ff', { clear = true })

-- ddu-ui-ff keymaps. (Inside the `ddu-ff` buffer)

-- "ddu-ui-ff" buffer has filetype `ddu-ff`.
-- Mappings MUST be set via FileType autocmd so they apply to actual
-- ddu-ff buffers (hooks_file runs at plugin load time in an arbitrary buffer).
-- See :h ddu-ui-ff for detail
local function item_is_directory()
  local item = vim.fn['ddu#ui#get_item']() or {}
  local action = item.action or {}
  return action.isDirectory == true
end

local function current_options()
  return vim.fn['ddu#custom#get_current'](vim.b.ddu_ui_name) or {}
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'ddu-ff',
  group = ff_group,
  callback = function ()
    local opts = { buffer = true, silent = true }

    -- itemAction: narrow (directory) / default (file)
    vim.keymap.set('n', '<CR>', function ()
      local params = item_is_directory() and { name = 'narrow' } or { name = 'default' }
      vim.fn['ddu#ui#do_action']('itemAction', params)
    end, opts
    )

    -- Mouse action
    vim.keymap.set('n', '<2-LeftMouse>', function ()
      vim.fn['ddu#ui#do_action']('itemAction')
    end, opts
    )

    vim.keymap.set('n', '<Space>', function ()
      vim.fn['ddu#ui#do_action']('toggleSelectItem')
    end, opts
    )
    vim.keymap.set('x', '<Space>', function ()
      vim.fn['ddu#ui#do_action']('toggleSelectItem')
    end, opts
    )
    vim.keymap.set('n', '*', function ()
      vim.fn['ddu#ui#do_action']('toggleAllItems')
    end, opts
    )

    vim.keymap.set('n', 'i', function ()
      vim.fn['ddu#ui#do_action']('openFilterWindow')
    end, opts
    )
    vim.keymap.set('n', '<C-l>', function ()
      vim.fn['ddu#ui#do_action']('redraw', { method = 'refreshItems' })
    end, opts
    )
    vim.keymap.set('n', 'p', function ()
      vim.fn['ddu#ui#do_action']('previewPath')
    end, opts
    )
    vim.keymap.set('n', 'P', function ()
      vim.fn['ddu#ui#do_action']('togglePreview')
    end, opts
    )
    vim.keymap.set('n', 'q', function ()
      vim.fn['ddu#ui#do_action']('quit')
    end, opts
    )

    vim.keymap.set('n', 'a', function ()
      vim.fn['ddu#ui#do_action']('chooseAction')
    end, opts
    )
    vim.keymap.set('n', 'A', function ()
      vim.fn['ddu#ui#do_action']('inputAction')
    end, opts
    )
    vim.keymap.set('n', 'I', function ()
      vim.fn['ddu#ui#do_action']('chooseInput')
    end, opts
    )

    vim.keymap.set('n', 'o', function ()
      vim.fn['ddu#ui#do_action']('expandItem', { mode = 'toggle' })
    end, opts
    )
    vim.keymap.set('n', 'O', function ()
      vim.fn['ddu#ui#do_action']('collapseItem')
    end, opts
    )

    -- delete / trash (filer ui -> trash, else delete)
    -- Avoit mistapping now
    -- vim.keymap.set('n', 'd', function()
    --  local name = (vim.b.ddu_ui_name == 'filer') and 'trash' or 'delete'
    --  vim.fn['ddu#ui#do_action']('itemAction', { name = name })
    -- end, opts)

    -- edit / narrow (directory -> narrow, else edit)
    vim.keymap.set('n', 'e', function ()
      local name = item_is_directory() and 'narrow' or 'edit'
      vim.fn['ddu#ui#do_action']('itemAction', { name = name })
    end, opts
    )

    -- itemAction with user-input params (eval'd as vim expr)
    vim.keymap.set('n', 'E', function ()
      local params = vim.fn.eval(vim.fn.input('params: ', '{}'))
      vim.fn['ddu#ui#do_action']('itemAction', { params = params })
    end, opts
    )

    -- new file / new
    vim.keymap.set('n', 'N', function ()
      local name = (vim.b.ddu_ui_name == 'file') and 'newFile' or 'new'
      vim.fn['ddu#ui#do_action']('itemAction', { name = name })
    end, opts
    )

    vim.keymap.set('n', 'r', function ()
      vim.fn['ddu#ui#do_action']('itemAction', { name = 'quickfix' })
    end, opts
    )
    vim.keymap.set('n', 'yy', function ()
      vim.fn['ddu#ui#do_action']('itemAction', { name = 'yank' })
    end, opts
    )
    vim.keymap.set('n', 'gr', function ()
      vim.fn['ddu#ui#do_action']('itemAction', { name = 'grep' })
    end, opts
    )
    vim.keymap.set('n', 'n', function ()
      vim.fn['ddu#ui#do_action']('itemAction', { name = 'narrow' })
    end, opts
    )

    vim.keymap.set('n', 'K', function ()
                    -- TODO: check it
      vim.fn['ddu#ui#do_action']('kensaku')
    end, opts
    )

    vim.keymap.set('n', '<C-v>', function ()
      vim.fn['ddu#ui#do_action']('toggleAutoAction')
    end, opts
    )
    vim.keymap.set('n', '<C-p>', function ()
      vim.fn['ddu#ui#do_action']('previewExecute', { command = 'execute "normal! \\<C-y>"' })
    end, opts
    )
    vim.keymap.set('n', '<C-n>', function ()
      vim.fn['ddu#ui#do_action']('previewExecute', { command = 'execute "normal! \\<C-e>"' })
    end, opts
    )

    -- Switch options: matcher_files globs via cmdline#input
    vim.keymap.set('n', 'u', function ()
      local globs = vim.split(
        vim.fn['cmdline#input']('Filter files: ', '', 'file'), ',',
        { plain = true, trimempty = true }
      )
      vim.fn['ddu#ui#multi_actions']({
        { 'updateOptions', { filterParams = { matcher_files = { globs = globs } } } },
        { 'redraw', { method = 'refreshItems' } }
      })
    end, opts
    )

    -- Switch sources: file
    vim.keymap.set('n', 'ff', function ()
      vim.fn['ddu#ui#do_action']('updateOptions', { sources = { { name = 'file' } } })
      vim.fn['ddu#ui#do_action']('redraw', { method = 'refreshItems' })
    end, opts
    )

    vim.keymap.set('n', '<C-j>', function ()
      vim.fn['ddu#ui#do_action']('cursorNext')
    end, opts
    )
    vim.keymap.set('n', '<C-k>', function ()
      vim.fn['ddu#ui#do_action']('cursorPrevious')
    end, opts
    )

    -- Widen ff window
    vim.keymap.set('n', '>', function ()
      vim.fn['ddu#ui#do_action']('updateOptions', { uiParams = { ff = { winWidth = 80 } } })
      vim.fn['ddu#ui#do_action']('redraw', { method = 'uiRedraw' })
    end, opts
    )

    -- pathFilter (ff)
    vim.keymap.set('n', 'M', function ()
      local cur = current_options()
      local uiParams = (cur.uiParams or {})
      local ffParams = (uiParams.ff or {})
      local pathFilter = vim.fn.input('pathFilter regexp: ', ffParams.pathFilter or '')
      vim.fn['ddu#ui#multi_actions']({
        { 'updateOptions', { uiParams = { ff = { pathFilter = pathFilter } } } },
        { 'redraw', { method = 'refreshItems' } }
      })
    end, opts
    )

    -- rg globs
    vim.keymap.set('n', 'U', function ()
      local cur = current_options()
      local sourceParams = (cur.sourceParams or {})
      local rgParams = (sourceParams.rg or {})
      local default = table.concat(rgParams.globs or {}, ' ')
      local globs = vim.split(vim.fn.input('rg globs: ', default), '%s+', { trimempty = true })
      vim.fn['ddu#ui#multi_actions']({
        { 'updateOptions', { sourceParams = { rg = { globs = globs } } } },
        { 'redraw', { method = 'refreshItems' } }
      })
    end, opts
    )
  end
})
-- }}}

-- ddu-ff {{{
lua << EOF
-- ==========================================================================
-- KEYMAPS
-- ==========================================================================
-- Global (non-buffer) cursor move on the "files" ddu instance.
vim.keymap.set('n', '<C-n>', function ()
  vim.fn['ddu#ui#multi_actions']({ 'cursorNext', 'itemAction' }, 'files')
end, { silent = true }
)
vim.keymap.set('n', '<C-p>', function ()
  vim.fn['ddu#ui#multi_actions']({ 'cursorPrevious', 'itemAction' }, 'files')
end, { silent = true }
)
EOF
-- }}}

