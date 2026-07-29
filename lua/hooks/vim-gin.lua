-- lua_add {{{
vim.g.gin_proxy_disable_editor = true

-- mappings (GIT) {{{

-- Gin: patch
vim.keymap.set('n', '[GIT]ad', function()
  -- {{{
  vim.cmd.GinPatch('++opener=tabnew', '%')
end, { desc = 'Gin: patch (tabnew)' }) -- }}}
-- Add points ( `%`: current buffer, cancel is may `:cq`)
vim.keymap.set('n', '[GIT]aD', function()
  -- {{{
  vim.notify('TODO: implements to call `!git add --patch<Space>` with `ddt`')
end, { desc = 'git add patch' }) -- }}}
-- Add file
vim.keymap.set('n', '[GIT]ai', function()
  -- {{{
  vim.notify('TODO: implements to call `<Cmd>!git add --interactive<CR>` with `ddt`')
end, { desc = 'git add interactive' }) -- }}}

-- Amend commit
vim.keymap.set('n', '[GIT]am', function()
  -- {{{
  vim.cmd('terminal git commit --amend')
end, { desc = 'Git: amend commit' }) -- }}}

-- branch
-- Use `;gb` (ddu-source-git_branch) and `itemAction`
vim.keymap.set('n', '[GIT]b', function()
  require('shared.ddu_git_branch').start()
end, { desc = 'Ddu: git branch' })

-- Commit (added): [GIT]c
vim.keymap.set('n', '[GIT]c', function()
  -- {{{
  vim.cmd('terminal git commit -v')
end, { desc = 'Git: commit' }) -- }}}

-- Diff
vim.keymap.set('n', '[GIT]d', function()
  -- {{{
  vim.cmd.GinDiff('++opener=tabnew')
end) -- }}}
-- Diff (Staged)
vim.keymap.set('n', '[GIT]D', function()
  -- {{{
  vim.cmd.GinDiff('++opener=tabnew', '--cached')
end) -- }}}

-- Log (with graph): [GIT]l(or L)
vim.keymap.set('n', '[GIT]l', function()
  -- {{{
  vim.cmd.GinLog('--all', '--graph', '--max-count=100', '--oneline', '--decorate')
end, { desc = 'Gin: log (all graph)' }) -- }}}

-- git pull
vim.keymap.set('n', '[GIT]p', function()
  -- {{{
  vim.cmd('!git pull origin @')
end, { desc = 'Git: pull' }) -- }}}
-- git push
vim.keymap.set('n', '[GIT]P', function()
  -- {{{
  vim.cmd('!git push origin @')
end, { desc = 'Git: push origin' }) -- }}}

-- Gin status
vim.keymap.set('n', '[GIT]s', function()
  -- {{{
  vim.cmd.GinStatus()
end, { desc = 'Gin: status' }) -- }}}
-- Git status
vim.keymap.set('n', '[GIT]S', function()
  -- {{{
  vim.cmd('!git status -v')
end, { desc = 'Git: status' }) -- }}}

-- Update: [GIT]u
vim.keymap.set('n', '[GIT]u', function()
  -- {{{
  vim.cmd('silent !git add --update')
end, { silent = true, desc = 'git add --update' }) -- }}}
-- }}}

-- }}}

