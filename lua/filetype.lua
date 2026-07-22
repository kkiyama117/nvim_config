-- Global variables and AutoCmd
-- See `lua/hooks/ft.lua` about buffer local settings.
-- zsh {{{
-- }}}

-- Tex {{{
vim.g.tex_flavor = 'latex'
-- }}}

-- help {{{
vim.g.help_example_languages = {
  lua = 'lua',
  sh = 'zsh',
  typescript = 'typescript',
  vim = 'vim',
}
-- }}}

-- Config for $NVIM_CONFIG_HOME {{{
local config_home = vim.env.NVIM_CONFIG_HOME
if config_home then
  local home = config_home:sub(-1) == '/' and config_home or config_home .. '/'
  -- capture the global defaults once, before any window-local override is applied
  local default_foldmethod = vim.go.foldmethod
  local default_foldenable = vim.go.foldenable
  -- When Editing files in $NVIM_CONFIG_HOME ...
  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = 'MyAutoCmd',
    pattern = { '*.lua', '*.vim', '*.ts' },
    callback = function(ctx)
      local fname = vim.api.nvim_buf_get_name(ctx.buf)
      -- On BufWinEnter, ctx.buf is the buffer of the window being entered,
      -- so vim.wo[0] targets that window.
      if fname:sub(1, #home) == home then
        -- Fold with `{{{` and `}}}` markers only in $NVIM_CONFIG_HOME lua/vim files.{{{
        vim.wo[0].foldmethod = 'marker'
        vim.wo[0].foldmarker = '{{{,}}}'
        vim.wo[0].foldenable = true
        -- }}}
        -- Set `:help` when put `K`{{{
        vim.bo.keywordprg = ':help'
        -- }}}
      else
        vim.wo[0].foldmethod = default_foldmethod
        vim.wo[0].foldenable = default_foldenable
      end
    end,
  })
end

-- Wait for dpp.make_state() to finish before exit {{{
-- dpp#make_state() deletes the old state files synchronously, then asks the
-- denops server (a separate Deno process) to regenerate them asynchronously.
-- Deno writes state.vim / startup.vim only at the very end (after re-importing
-- and recompiling the TS config), and fires `User Dpp:makeStatePost` only then.
-- If Neovim exits before that, the state is lost and every restart falls back
-- to the slow DenopsReady path (infinite slow-path loop).
--
-- dpp_loader.lua sets g:dpp_make_state_in_progress = v:true before every
-- dpp.make_state() call, and the Dpp:makeStatePost autocmd clears it.  Here
-- we only wait when a make_state is actually in flight; otherwise we return
-- immediately.  vim.wait pumps the event loop so the denops RPC notification
-- that triggers Dpp:makeStatePost is delivered during the wait.
local DPP_MAKE_STATE_WAIT_MS = 15000
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = 'MyAutoCmd',
  callback = function()
    if vim.g.dpp_make_state_in_progress ~= true then
      return
    end
    vim.notify('Waiting for `dpp#make_state` to finish before exit...',
      vim.log.levels.INFO)
    local ok = vim.wait(DPP_MAKE_STATE_WAIT_MS, function()
      return vim.g.dpp_make_state_in_progress ~= true
    end, 50)
    if not ok then
      vim.notify(
        'dpp#make_state() did not finish in time; state may be stale',
        vim.log.levels.WARN)
    end
  end,
})
-- }}}
-- }}}

-- Markdown {{{
-- Remove ' from iskeyword so word motions skip quotes {{{
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufRead', 'BufNewFile' }, {
  group = 'MyAutoCmd',
  pattern = '*.md',
  callback = function()
    vim.bo.iskeyword = vim.bo.iskeyword:gsub(",'", '')
  end,
})
-- }}}
-- }}}

-- Git commit: append diff to buffer (requires append_diff implementation) {{{
-- TODO: implement equivalent of vimrc#append_diff() to show staged diff
-- vim.api.nvim_create_autocmd('BufReadPost', {
--   group = 'MyAutoCmd',
--   pattern = 'COMMIT_EDITMSG',
--   callback = function()
--     -- vim.fn.append_diff() or similar
--   end,
-- })
-- }}}

-- Xonsh{{{
vim.api.nvim_create_autocmd('BufReadPost', {
  group = 'MyAutoCmd',
  pattern = '*.xonsh',
  callback = function()
    vim.bo.filetype = 'python'
  end,
})
-- }}}

-- Global AutoCmds ==========================================================
-- Update filetype on write {{{
vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'MyAutoCmd',
  pattern = '*',
  callback = function()
    if vim.bo.filetype == '' or vim.b.ftdetect then
      vim.b.ftdetect = nil
      vim.cmd('filetype detect')
    end
  end,
})
-- }}}

-- Make script files executable on write {{{
vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'MyAutoCmd',
  pattern = '*',
  callback = function()
    local file = vim.fn.expand('<afile>')
    local line = vim.fn.getline(1)
    if line:find('^#!/') == 1 then
      local perm = vim.fn.getfperm(file)
      local newperm = perm:sub(1, 2) .. 'x' .. perm:sub(4, 5) .. 'x' .. perm:sub(7, 8) .. 'x'
      if perm ~= newperm then
        vim.fn.setfperm(file, newperm)
      end
    end
  end,
})
-- }}}

-- Make directory automatically on write {{{
vim.api.nvim_create_autocmd('BufWritePre', {
  group = 'MyAutoCmd',
  pattern = '*',
  callback = function()
    local dir = vim.fn.expand('<afile>:p:h')
    if vim.fn.isdirectory(dir) == 1 or vim.bo.buftype ~= '' then
      return
    end
    local message = string.format('"%s" does not exist. Create? [y/N] ', dir)
    if vim.fn.input(message):match('^y%es?$') then
      vim.fn.mkdir(dir, 'p')
    end
  end,
})
-- }}}

-- Remove saved empty file automatically {{{
vim.api.nvim_create_autocmd('BufWritePost', {
  group = 'MyAutoCmd',
  pattern = '*',
  callback = function()
    local file = vim.fn.expand('<afile>:p')
    if vim.fn.filereadable(file) == 0 or vim.bo.buftype ~= '' then
      return
    end
    local lines = vim.fn.readfile(file, '', 1)
    if #lines > 0 then
      return
    end
    local message = string.format('"%s" is empty. Remove? [y/N] ', file)
    if vim.fn.input(message):match('^y%es?$') then
      vim.cmd('enew')
      vim.fn.delete(file)
      vim.cmd('bdelete ' .. vim.fn.bufnr(file))
    end
  end,
})
-- }}}

-- Disable syntax for huge files (>1MB) {{{
vim.api.nvim_create_autocmd('BufReadPre', {
  group = 'MyAutoCmd',
  pattern = '*',
  callback = function()
    local file = vim.fn.expand('<afile>')
    if vim.fn.getfsize(file) > 1000000 then
      vim.opt_local.eventignorewin:append('FileType')
    end
  end,
})
-- }}}

-- Wrap for zsh edit-command-line (tmp files) {{{
vim.api.nvim_create_autocmd('BufRead', {
  group = 'MyAutoCmd',
  pattern = '/tmp/*',
  callback = function()
    vim.wo.wrap = true
  end,
})
-- }}}

-- Disable default plugins (netrw, etc.) {{{
vim.g.loaded_2html_plugin = true
vim.g.loaded_getscriptPlugin = true
vim.g.loaded_gtags = true
vim.g.loaded_gtags_cscope = true
vim.g.loaded_gzip = true
vim.g.loaded_logiPat = true
vim.g.loaded_man = true
vim.g.loaded_matchit = true
vim.g.loaded_matchparen = true
vim.g.loaded_netrwFileHandlers = true
vim.g.loaded_netrwPlugin = true
vim.g.loaded_netrwSettings = true
vim.g.loaded_shada_plugin = true
vim.g.loaded_spellfile_plugin = true
vim.g.loaded_tarPlugin = true
vim.g.loaded_tutor_mode_plugin = true
vim.g.loaded_vimballPlugin = true
vim.g.loaded_zipPlugin = true
-- }}}

