-- lua_add {{{
-- ==========================================================================
-- KEYMAPS
-- ==========================================================================
local split = vim.fn.has('nvim') == 1 and 'floating' or 'horizontal'

-- `Dark Powered` alternative keys; `/`, `*`, `n` --{{{
vim.keymap.set('n', '/', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    uiParams = {
      ff = {
        ignoreEmpty = true,
      },
    },
    sources = {
      {
        name = 'line',
        params = {
          ignoreEmptyInput = true,
        },
      },
    },
    --input = vim.fn.escape(vim.fn.input('Pattern: '), ' '),
    input = vim.fn.escape(vim.fn['cmdline#input'](), ' '),
  })
end, { desc = 'Search `/` alternative' }) -- }}}

vim.keymap.set('n', '*', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    input = vim.fn.expand('<cword>'),
    sources = {
      {
        name = 'line',
      },
    },
  })
end) -- }}}

vim.keymap.set('n', 'n', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = true,
  })
end) -- }}}

vim.keymap.set('n', 'sm', function() -- {{{
  vim.fn['ddu#start']({
    sources = {
      {
        name = 'dpp',
      },
    },
  })
end) -- }}}

-- }}}

-- Dark powered plugins are mapped to `<Leader>d` = `[DP]`
-- Almost all of this mappings are for searching file names{{{
--Search files from `old`,`git`, and so on
vim.keymap.set('n', '[DP]a', function() -- {{{
  local git_source = vim.fn.finddir('.git', ';') ~= '' and 'file_git' or ''
  vim.fn['ddu#start']({
    name = 'files-' .. vim.fn.win_getid(),
    resume = true,
    unique = true,
    expandInput = true,
    sources = vim.fn.filter({ { name = 'file_old' }, { name = git_source }, { name = 'file' } }, 'v:val.name != ""'),
    sourceOptions = {
      file = {
        volatile = true,
      },
    },
    sourceParams = {
      file_new = {},
    },
    uiParams = {
      ff = {
        displaySourceName = 'short',
        split = split,
      },
    },
  })
end, { desc = 'Ddu: file picker (old + git + file)' }) -- }}}

-- NVIM_CONFIG_HOME file list
vim.keymap.set('n', '[DP]c', function() -- {{{
  local path = vim.g.nvim_config_home
  vim.fn['ddu#start']({
    name = 'files',
    resume = true,
    sources = {
      {
        name = 'file',
      },
    },
    sourceOptions = {
      file = {
        path = path,
      },
    },
    uiParams = {
      ff = {
        split = split,
      },
    },
  })
end, { desc = 'Ddu: $NVIM_CONFIG_HOME files' }) -- }}}

-- Ddu-ui-filer open at side
vim.keymap.set('n', '[DP]f', function() -- {{{
  vim.fn['ddu#start']({
    name = 'filer-' .. vim.fn.win_getid(),
    ui = 'filer',
    resume = true,
    sync = true,
    sources = {
      {
        name = 'file',
      },
    },
    sourceOptions = {
      file = {
        path = vim.t.ddu_ui_filer_path or vim.fn.getcwd(),
        limitPath = vim.fn.getcwd(),
        columns = { 'filename' },
      },
    },
    uiParams = {
      filer = {
        autoResize = true,
        split = 'vertical',
      },
    },
  })
end, { desc = 'ddu-ui-filer: open' })
-- }}}

-- Open files/Uri from pointed word
vim.keymap.set('n', '[DP]p', function() -- {{{
  -- moved from `sf`
  vim.fn['ddu#start']({
    name = 'files-' .. vim.fn.win_getid(),
    sources = {
      {
        name = 'file_point',
      },
    },
    uiParams = {
      ff = {
        split = split,
        displaySourceName = 'short',
      },
    },
  })
end, { desc = 'Ddu: extract file paths from cursor line' }) -- }}}

-- }}}

-- Fuzzy finder mappings that start from `;` {{{

-- Normal mapping {{{

-- outline (markdown)
vim.keymap.set('n', ';d', function() -- {{{
  vim.fn['ddu#start']({
    name = 'outline',
    sources = {
      {
        name = 'markdown',
      },
    },
    uiParams = {
      ff = {
        ignoreEmpty = true,
        displayTree = true,
      },
    },
  })
end, { desc = 'Ddu: markdown outline' }) -- }}}

-- simple ripgrep with empty window
vim.keymap.set('n', ';e', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    sources = {
      {
        name = 'rg',
      },
    },
    sourceParams = {
      rg = {
        volatile = true,
      },
    },
  })
end, { desc = 'Ddu: empty' }) -- }}}

-- ripgrep with path
vim.keymap.set('n', ';f', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    sources = {
      {
        name = 'rg',
      },
    },
    uiParams = { ff = {
      ignoreEmpty = true,
    } },
    sourceParams = {
      rg = {
        input = vim.fn['cmdline#input']('Pattern: ', vim.fn.expand('<cword>')),
      },
    },
    sourceOptions = {
      rg = {
        path = vim.fn['cmdline#input']('Directory: ', vim.fn.getcwd() .. '/', 'dir'),
      },
    },
  })
end, { desc = 'Ddu: ripgrep with manual path' }) -- }}}

-- ripgrep
vim.keymap.set('n', ';g', function() -- {{{
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    sources = {
      {
        name = 'rg',
      },
    },
    sourceParams = {
      rg = {
        input = vim.fn.escape(vim.fn['cmdline#input']('Pattern: ', vim.fn.expand('<cword>')), ' '),
      },
    },
    uiParams = {
      ff = {
        ignoreEmpty = true,
      },
    },
  })
end, { desc = 'Ddu: ripgrep' }) -- }}}}

-- help
vim.keymap.set('n', ';h', function()
  vim.fn['ddu#start']({
    --name = 'search',
    sources = {
      {
        name = 'help',
      },
    },
  })
end, { desc = 'Ddu: help' })

-- Command output
vim.keymap.set('n', ';o', function() -- {{{
  vim.fn['ddu#start']({
    name = 'output',
    sources = {
      {
        name = 'output',
      },
    },
    sourceParams = {
      output = {
        command = vim.fn['cmdline#input']('Command: ', '', 'command'),
      },
    },
  })
end, { desc = 'Ddu: output command' }) -- }}}

-- register
vim.keymap.set('n', ';r', function() -- {{{
  vim.fn['ddu#start']({
    name = 'register',
    sourceOptions = {
      register = {
        defaultAction = vim.fn.col('.') == 1 and 'insert' or 'append',
      },
    },
    uiParams = {
      ff = {
        autoResize = true,
      },
    },
  })
end, { desc = 'Ddu: register' }) -- }}}

-- }}}

-- Visual mapping {{{
-- yank line and use it as a input of ripgrep
vim.keymap.set('x', ';g', function() -- {{{
  vim.cmd('normal! y')
  vim.fn['ddu#start']({
    name = 'search',
    resume = false,
    sources = {
      {
        name = 'rg',
      },
    },
    sourceParams = {
      rg = {
        input = vim.fn.escape(vim.fn['cmdline#input']('Pattern: ', vim.fn.getreg('"')), ' '),
      },
    },
    uiParams = {
      ff = {
        ignoreEmpty = true,
      },
    },
  })
end, { desc = 'Ddu: ripgrep (visual)' }) -- }}}

-- URL action (visual)
vim.keymap.set('x', ';G', function() -- {{{
  local region = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos('.'), { type = vim.fn.mode() })
  if vim.fn.empty(region) == 1 then
    return
  end
  local url = region[1]:gsub('%s*\n?$', '')
  local items = {
    {
      word = url,
      kind = 'url',
      action = {
        url = url,
      },
    },
  }
  vim.fn['ddu#start']({
    sources = {
      {
        name = 'action',
      },
    },
    sourceParams = {
      action = {
        items = items,
      },
    },
  })
end, { desc = 'Ddu: URL action (visual)' }) -- }}}

-- register (visual, expr)
vim.keymap.set('x', ';r', function() -- {{{
  local prefix = vim.fn.mode() == 'V' and '"_R<Esc>' or '"_d'
  vim.fn['ddu#start']({
    name = 'register',
    sources = {
      {
        name = 'register',
      },
    },
    sourceOptions = {
      ff = {
        defaultAction = 'insert',
      },
    },
    uiParams = {
      ff = {
        autoResize = true,
      },
    },
  })
end, { expr = true, desc = 'Ddu: register (visual)' }) --}}}

-- }}}

-- }}}

-- AutoCmd for Filter window (keymap `<C-f>` and `<C-b>`) -- {{{
vim.api.nvim_create_autocmd('User', {
  pattern = 'Ddu:uiOpenFilterWindow',
  group = 'MyAutoCmd',
  callback = function() -- {{{
    vim.opt.cursorline = true
    vim.fn['ddu#ui#save_cmaps']({ '<C-f>', '<C-b>' })
    vim.api.nvim_buf_set_keymap(
      0,
      'c',
      '<C-f>',
      '<Cmd>call ddu#ui#do_action("cursorNext", {"loop": v:true})<CR>',
      { noremap = true, silent = true }
    )
    vim.api.nvim_buf_set_keymap(
      0,
      'c',
      '<C-b>',
      '<Cmd>call ddu#ui#do_action("cursorPrevious", {"loop": v:true})<CR>',
      { noremap = true, silent = true }
    )
  end,
}) -- }}}

vim.api.nvim_create_autocmd('User', {
  pattern = 'Ddu:uiCloseFilterWindow',
  group = 'MyAutoCmd',
  callback = function() -- {{{
    vim.opt.cursorline = false
    vim.fn['ddu#ui#restore_cmaps']()
  end,
}) -- }}}
-- }}}

-- }}}

-- lua_source {{{
vim.fn['ddu#custom#load_config'](vim.fn.stdpath('config') .. '/denops/ddu.ts')
-- }}}

