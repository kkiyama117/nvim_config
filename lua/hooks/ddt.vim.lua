-- lua_add {{{
-- Start ddt shell
vim.keymap.set('n', '[DP]s', function() -- {{{
  vim.fn['ddt#start']({
    name = vim.t.ddt_ui_shell_last_name or ('shell-' .. vim.fn.win_getid()),
    ui = 'shell',
  })
end, { desc = 'ddt: shell' }) -- }}}
-- Start ddt terminal
vim.keymap.set('n', '[DP]t', function() -- {{{
  vim.fn['ddt#start']({
    name = vim.t.ddt_ui_terminal_last_name or ('terminal-' .. vim.fn.win_getid()),
    ui = 'terminal',
  })
end, { desc = 'ddt: terminal' }) -- }}}

-- Ddu tab switcher
vim.keymap.set('n', '<C-t>', function() -- {{{
  local split = vim.fn.has('nvim') == 1 and 'floating' or 'horizontal'
  vim.fn['ddu#start']({
    name = 'ddt',
    sync = true,
    uiParams = {
      ff = {
        split = split,
        winRow = 1,
        autoResize = true,
        cursorPos = vim.fn.tabpagenr(),
      },
    },
    sources = {
      { name = 'ddt_tab' },
    },
  })
end, { desc = 'ddt: tab switcher' }) -- }}}

-- Send selected text to current ddt UI
vim.keymap.set('x', '<Space>', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', {
    str = table.concat(vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos('.'), { type = vim.fn.mode() }), '\n'),
  }, vim.t.ddt_ui_name)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', false)
end, { desc = 'ddt: send selection' }) -- }}}

-- Kill editor
vim.keymap.set('n', 'sD', function() -- {{{
  vim.fn['ddt#ui#kill_editor']()
end, { desc = 'ddt: kill editor' }) -- }}}

-- }}}

-- lua_source {{{
-- load denops file
vim.fn['ddt#custom#load_config'](vim.fn.expand('$NVIM_CONFIG_HOME/denops/ddt.ts'))

-- MyGitStatus function (used in statusline)
local job = require('job')
local cached_status = {}

-- TODO: use plugin maybe.
function _G.MyGitStatus() -- {{{
  local gitdir = vim.fn.finddir('.git', ';')
  if gitdir == '' then
    return ''
  end

  local full_gitdir = vim.fn.fnamemodify(gitdir, ':p')
  local gitdir_time = vim.fn.getftime(full_gitdir)
  local now = vim.fn.localtime()

  if
    not cached_status[full_gitdir]
    or gitdir_time > cached_status[full_gitdir].timestamp
    or now > cached_status[full_gitdir].check + 1
  then
    -- Get normal git status.
    -- The leading space separates the branch from the cwd that `userPrompt`
    -- (see `denops/ddt.ts`) prepends.
    local branch = vim.fn.trim(job.system({ 'git', 'rev-parse', '--abbrev-ref', 'HEAD' }))
    local status_lines = { ' ' .. branch }

    local git_status_output = job.system({ 'git', 'status', '--short', '--ignore-submodules=all' })
    for _, line in ipairs(vim.fn.split(git_status_output, '\n')) do
      if line ~= '' then
        table.insert(status_lines, '| ' .. line)
      end
    end

    local status = table.concat(status_lines, '\n')

    -- Detect unsaved buffers
    for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if buf.changed == 1 and buf.name ~= '' then
        status = status .. '\n'
        status = status .. ('| ?? ' .. vim.fn.fnamemodify(buf.name, ':.') .. ' (unsaved)')
      end
    end

    cached_status[full_gitdir] = {
      check = now,
      timestamp = gitdir_time,
      status = status,
    }
  end

  return cached_status[full_gitdir].status
end -- }}}

-- Set terminal colors
-- {{{
vim.g.terminal_color_0 = '#6c6c6c'
vim.g.terminal_color_1 = '#ff6666'
vim.g.terminal_color_2 = '#66ff66'
vim.g.terminal_color_3 = '#ffd30a'
vim.g.terminal_color_4 = '#1e95fd'
vim.g.terminal_color_5 = '#ff13ff'
vim.g.terminal_color_6 = '#1bc8c8'
vim.g.terminal_color_7 = '#c0c0c0'
vim.g.terminal_color_8 = '#383838'
vim.g.terminal_color_9 = '#ff4444'
vim.g.terminal_color_10 = '#44ff44'
vim.g.terminal_color_11 = '#ffb30a'
vim.g.terminal_color_12 = '#6699ff'
vim.g.terminal_color_13 = '#f820ff'
vim.g.terminal_color_14 = '#4ae2e2'
vim.g.terminal_color_15 = '#ffffff'
-- }}}

-- Terminal mode keymaps (pum.vim integration) {{{
vim.keymap.set('t', '<C-t>', '<Tab>', {desc="original <Tab>"})
-- NOTE: pum.vim actions must be deferred through <Cmd>, not called while the
-- <expr> mapping is being evaluated (textlock).
vim.keymap.set('t', '<Tab>', function() -- {{{
  if vim.fn['pum#visible']() == 1 then
    return '<Cmd>call pum#map#select_relative(+1)<CR>'
  end
  return '<Tab>'
end, { expr = true, desc = '' }) -- }}}
vim.keymap.set('t', '<S-Tab>', function() -- {{{
  if vim.fn['pum#visible']() == 1 then
    return '<Cmd>call pum#map#select_relative(-1)<CR>'
  end
  return '<S-Tab>'
end, { expr = true }) -- }}}
vim.keymap.set('t', '<Down>', function() -- {{{
  vim.fn['pum#map#insert_relative'](1)
end) -- }}}
vim.keymap.set('t', '<Up>', function() -- {{{
  vim.fn['pum#map#insert_relative'](-1)
end) -- }}}
vim.keymap.set('t', '<C-y>', function() -- {{{
  if vim.fn['pum#visible']() == 1 then
    return '<Cmd>call pum#map#confirm()<CR>'
  end
  -- Terminal mode has no register paste, so prompt for the text instead.
  return '<Cmd>call feedkeys(""->input(), "n")<CR>'
end, { expr = true }) -- }}}
vim.keymap.set('t', '<C-o>', function() -- {{{
  vim.fn['pum#map#confirm']()
end) -- }}}
-- }}}
-- }}}

-- ddt-terminal {{{
lua << EOF
-- Keymaps {{{
-- Normal Mode {{{
vim.keymap.set('n', '<CR>', function() -- {{{
  vim.fn['ddt#ui#do_action']('executeLine')
end, { buffer = true, desc = 'ddt-terminal: execute line' }) -- }}}
vim.keymap.set('n', '<C-n>', function() -- {{{
  vim.fn['ddt#ui#do_action']('nextPrompt')
end, { buffer = true, desc = 'ddt-terminal: next prompt' }) -- }}}
vim.keymap.set('n', '<C-p>', function() -- {{{
  vim.fn['ddt#ui#do_action']('previousPrompt')
end, { buffer = true, desc = 'ddt-terminal: previous prompt' }) -- }}}
vim.keymap.set('n', '<C-y>', function() -- {{{
  vim.fn['ddt#ui#do_action']('pastePrompt')
end, { buffer = true, desc = 'ddt-terminal: paste prompt' }) -- }}}
vim.keymap.set('n', '<C-h>', function() -- {{{
  vim.fn['ddu#start']({
    name = 'ddt',
    sync = true,
    input = vim.fn['ddt#ui#get_input'](),
    sources = {
      { name = 'ddt_shell_history' },
    },
  })
end, { buffer = true, desc = 'ddt-terminal: shell history' }) -- }}}
vim.keymap.set('n', 'I', function() -- {{{
  vim.cmd('split')
  vim.fn['ddu#start']({
    name = vim.t.ddt_ui_terminal_last_name,
    sources = {
      { name = 'junkfile' },
    },
    sourceOptions = {
      junkfile = {
        volatile = true,
      },
    },
    resume = true,
    uiParams = {
      ff = {
        split = 'no',
      },
    },
  })
end, { buffer = true, desc = 'ddt-terminal: launch ddu' }) -- }}}
-- Aliases {{{
vim.keymap.set('n', '<Leader>gd', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git diff' })
end, { buffer = true, desc = 'ddt-terminal: git diff' }) -- }}}
vim.keymap.set('n', '<Leader>gc', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git commit' })
end, { buffer = true, desc = 'ddt-terminal: git commit' }) -- }}}
vim.keymap.set('n', '<Leader>gs', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git status' })
end, { buffer = true, desc = 'ddt-terminal: git status' }) -- }}}
vim.keymap.set('n', '<Leader>ga', function() -- {{{
  vim.fn['ddt#ui#do_action']('setPrompt', { str = 'git add ' })
  vim.api.nvim_feedkeys('A', 'n', false)
end, { buffer = true, desc = 'ddt-terminal: git add' }) -- }}}
vim.keymap.set('n', '<Leader>gA', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git commit --amend' })
end, { buffer = true, desc = 'ddt-terminal: git commit --amend' }) -- }}}
-- }}}
-- }}}
-- Visual Mode {{{
vim.keymap.set('x', '<CR>', function() -- {{{
  vim.fn['ddt#ui_action'](vim.t.ddt_ui_terminal_last_name, 'send', {
    str = table.concat(vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos('.'), { type = vim.fn.mode() }), '\n'),
  })
end, { desc = 'ddt-terminal: send selection' }) -- }}}
-- }}}
-- }}}

-- DirChanged autocmd for ddt-terminal {{{
vim.api.nvim_create_autocmd('DirChanged', {
  buffer = 0,
  group = vim.api.nvim_create_augroup('ddt-ui-terminal', { clear = true }),
  callback = function()
    if vim.v.event.cwd and vim.t.ddt_ui_last_directory ~= vim.v.event.cwd then
      vim.fn['ddt#ui#do_action']('cd', { directory = vim.v.event.cwd })
    end
  end,
})
-- }}}

-- Restore ddt terminal directory {{{
if vim.b.ddt_terminal_directory then
  vim.cmd('tcd ' .. vim.fn.fnameescape(vim.b.ddt_terminal_directory))
end
-- }}}

EOF
-- }}}

-- ddt-shell {{{
lua << EOF
-- Keymaps {{{
vim.keymap.set({'n','i'}, '<CR>', function() -- {{{
  vim.fn['ddt#ui#do_action']('executeLine')
end, { buffer = true, desc = 'ddt-shell: execute line' }) -- }}}
-- Normal Mode {{{
vim.keymap.set('n', '<C-n>', function() -- {{{
  vim.fn['ddt#ui#do_action']('nextPrompt')
end, { buffer = true, desc = 'ddt-shell: next prompt' }) -- }}}
vim.keymap.set('n', '<C-p>', function() -- {{{
  vim.fn['ddt#ui#do_action']('previousPrompt')
end, { buffer = true, desc = 'ddt-shell: previous prompt' }) -- }}}
vim.keymap.set('n', '<C-y>', function() -- {{{
  vim.fn['ddt#ui#do_action']('pastePrompt')
end, { buffer = true, desc = 'ddt-shell: paste prompt' }) -- }}}
vim.keymap.set('n', '<C-h>', function() -- {{{
  vim.fn['ddu#start']({
    name = 'ddt',
    sync = true,
    input = vim.fn['ddt#ui#get_input'](),
    sources = {
      { name = 'ddt_shell_history' },
    },
  })
end, { buffer = true, desc = 'ddt-shell: shell history' }) -- }}}
-- Aliases {{{
vim.keymap.set('n', '<Leader>gd', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git diff' })
end, { buffer = true, desc = 'ddt-shell: git diff' }) -- }}}
vim.keymap.set('n', '<Leader>gc', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git commit' })
end, { buffer = true, desc = 'ddt-shell: git commit' }) -- }}}
vim.keymap.set('n', '<Leader>gs', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git status' })
end, { buffer = true, desc = 'ddt-shell: git status' }) -- }}}
vim.keymap.set('n', '<Leader>ga', function() -- {{{
  vim.fn['ddt#ui#do_action']('setPrompt', { str = 'git add ' })
  vim.api.nvim_feedkeys('A', 'n', false)
end, { buffer = true, desc = 'ddt-shell: git add' }) -- }}}
vim.keymap.set('n', '<Leader>gA', function() -- {{{
  vim.fn['ddt#ui#do_action']('send', { str = 'git commit --amend' })
end, { buffer = true, desc = 'ddt-shell: git commit --amend' }) -- }}}
vim.keymap.set('n', '<Leader>gp', function() -- {{{
  vim.fn['ddt#ui#do_action']('setPrompt', { str = 'git push' })
end, { buffer = true, desc = 'ddt-shell: git push' }) -- }}}
-- }}}
-- }}}
-- Insert Mode {{{
vim.keymap.set('i', '<C-n>', function() -- {{{
  if vim.fn['pum#visible']() == 1 then
    return '<Cmd>call pum#map#insert_relative(+1, "empty")<CR>'
  end
  return vim.fn['ddc#map#manual_complete']({ sources = { 'shell_history' } })
end, { buffer = true, expr = true, desc = 'ddt-shell: complete next' }) -- }}}
vim.keymap.set('i', '<C-p>', function() -- {{{
  if vim.fn['pum#visible']() == 1 then
    return '<Cmd>call pum#map#insert_relative(-1, "empty")<CR>'
  end
  return vim.fn['ddc#map#manual_complete']({ sources = { 'shell_history' } })
end, { buffer = true, expr = true, desc = 'ddt-shell: complete previous' }) -- }}}
vim.keymap.set('i', '<C-c>', function() -- {{{
  vim.fn['ddt#ui#do_action']('terminate')
end, { buffer = true, desc = 'ddt-shell: terminate' }) -- }}}
vim.keymap.set('i', '<C-z>', function() -- {{{
  vim.fn['ddt#ui#do_action']('pushBufferStack')
end, { buffer = true, desc = 'ddt-shell: push buffer stack' }) -- }}}
-- }}}
-- }}}
-- DirChanged autocmd for ddt-shell AutoCmd {{{
vim.api.nvim_create_autocmd('DirChanged', {
  buffer = 0,
  group = vim.api.nvim_create_augroup('ddt-ui-shell', { clear = true }),
  callback = function()
    if vim.v.event.cwd and vim.t.ddt_ui_last_directory ~= vim.v.event.cwd then
      vim.fn['ddt#ui#do_action']('cd', { directory = vim.v.event.cwd })
    end
  end,
})
-- }}}
-- Restore shell directory {{{
if vim.b.ddt_shell_directory then
  vim.cmd('tcd ' .. vim.fn.fnameescape(vim.b.ddt_shell_directory))
end
-- }}}
EOF
-- }}}

