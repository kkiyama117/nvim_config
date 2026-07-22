-- dpp.vim manages plugins itself; no need for Vim's built-in packpath.
vim.o.packpath = ''

-- APPEARANCE {{{
-- SideBar {{{
-- Number {{{
vim.opt.number = true
vim.opt.relativenumber = true
-- }}}
-- SignColumn {{{
vim.opt.signcolumn = 'yes'
-- }}}
-- }}}
-- Charactor visual {{{
-- Match pairs {{{
vim.opt.matchpairs:append('<:>')
-- }}}
-- <TAB> and <CR> visible {{{
vim.opt.list = true
if vim.fn.has('win32') == 1 then
  vim.opt.listchars = 'tab:>-,trail:-,precedes:<'
else
  vim.opt.listchars = 'tab:▸ ,trail:-,precedes:«,nbsp:%'
end
vim.api.nvim_create_autocmd('InsertEnter', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function()
    vim.opt.listchars:remove('trail:-')
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  pattern = '*',
  group = 'MyAutoCmd',
  callback = function()
    vim.opt.listchars:append('trail:-')
  end,
})
-- }}}
-- }}}
-- Wrap and Break {{{
-- no wrap as a default
vim.opt.wrap = false
vim.opt.whichwrap:append('h,l,<,>,[,],b,s,~')
-- break
vim.opt.linebreak = true
vim.opt.showbreak = ' '
vim.opt.breakat = '  \t;:,!?'
vim.opt.breakindent = true
-- }}}
-- Scroll {{{
vim.opt.scrolloff = 8
if vim.fn.exists('+smoothscroll') == 1 then
  vim.opt.smoothscroll = true
end
if vim.fn.exists('+splitscroll') == 1 then
  -- Disable scroll when split
  vim.opt.splitscroll = false
end
-- }}}
-- Visual Bell{{{
vim.opt.visualbell = false
vim.opt.belloff = 'all'
-- }}}
-- FOLDING{{{
vim.opt.foldenable = false
vim.opt.foldmethod = 'manual'
vim.opt.foldcolumn = 'auto:1'
vim.opt.fillchars = 'fold:━'
vim.opt.commentstring = '%s'
-- }}}
-- MENUS (menu, wildmenu, popup){{{
-- `Menu`{{{
-- disable menu.vim
if vim.fn.has('gui_running') == 1 then
  vim.opt.guioptions = 'Mc'
end
-- disable menu
vim.g.did_install_default_menus = true
-- }}}
-- `Wild` {{{
-- Wildmenu {{{
-- Disable builtin completion menu (to use `ddc.vim`)
vim.opt.wildmenu = false
vim.opt.wildmode = 'full'
--vim.opt.wildmode = 'list:longest,full'
vim.opt.wildignorecase = true
vim.opt.showfulltag = true
-- }}}
-- Wild Options{{{
vim.opt.wildoptions:append('fuzzy')
-- "pum" wildoptions conflicts with pum.vim
vim.opt.wildoptions:remove('pum')
vim.opt.wildoptions:append('tagfile')
-- }}}
-- }}}
-- `Popup` {{{
-- Set popup menu options.
if vim.fn.exists('&pumopt') == 1 then
  vim.opt.pumopt = 'width:0,height:5,opacity:80,border:round'
else
  vim.opt.pumwidth = 0
  vim.opt.pumheight = 5
  vim.opt.pumborder = 'rounded'
end
-- }}}
-- }}}
-- WINDOW {{{
-- Maintain a current line at the time of movement as much as possible.
vim.opt.startofline = false
-- behavior of `split`{{{
vim.opt.splitbelow = true
vim.opt.splitright = true
-- No equal window size.
vim.opt.equalalways = false
-- }}}
-- Window size {{{
vim.opt.winheight = 1
vim.opt.winwidth = 30
-- Cmdline
vim.opt.cmdwinheight = 5
-- Preview and Help window
vim.opt.previewheight = 8
vim.opt.helpheight = 12
if vim.fn.exists('+previewpopup') == 1 then
  vim.opt.previewpopup = 'height:10,width:60'
end
-- }}}
-- }}}
-- BUFFER {{{
-- Display another buffer when current buffer isn't saved
vim.opt.hidden = true
-- }}}
-- CMDLINE OUTPUT {{{
-- Disable builtin message pager {{{
vim.opt.more = false
if vim.fn.exists('+messagesopt') == 1 then
  vim.opt.messagesopt = 'wait:1500,history:500'

  -- Enable hit-enter prompt when execute commands
  vim.api.nvim_create_autocmd('CmdlineEnter', {
    pattern = '*',
    group = 'MyAutoCmd',
    callback = function()
      vim.opt.messagesopt:append('hit-enter')
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorHold', 'InsertEnter' }, {
    pattern = '*',
    group = 'MyAutoCmd',
    callback = function()
      vim.opt.messagesopt:remove('hit-enter')
    end,
  })
end
-- }}}
-- }}}
-- }}}

-- COMPLETIONS {{{
-- We use `ddc.vim` (and LSP) as a default;
-- completion {{{
-- See configs of `ddc.vim`, `pum.vim` and `cmdline.vim` also.
vim.opt.completeopt = 'menuone'
if vim.fn.exists('+completepopup') == 1 then
  vim.opt.completeopt:append('popup')
  vim.opt.completepopup = 'height:4,width:60,highlight:InfoPopup'
end
-- Don't complete from other buffer
vim.opt.complete = '.'
-- }}}
-- omnifunc: 'omnifunc' is a string option (window-local) holding a
-- function *name*, not a function reference. Pass the LSP omnifunc via
-- `v:lua` so `<C-x><C-o>` invokes `vim.lsp.omnifunc` for the current buffer.
vim.opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
-- }}}

-- ENCODING, IME, Spell Check {{{1
vim.opt.fileencodings = 'utf-8,iso-2022-jp-3,euc-jp,cp932,ucs-bom'

if vim.fn.has('multi_byte_ime') == 1 then
  vim.opt.iminsert = 0
  vim.opt.imsearch = 0
end

-- Spell check {{{2
--vim.opt.spell = true
vim.opt.helplang = 'ja,en'
vim.opt.spelllang:append('cjk')
-- }}}2
-- File Format {{{2
vim.opt.fileformat = 'unix'
vim.opt.fileformats = 'unix,dos,mac'
-- }}}2
-- Disable editorconfig as a default
vim.g.editorconfig = false
-- }}}1

-- EDIT and FORMAT (Default) {{{1
-- Tab {{{2
vim.opt.expandtab = true
vim.opt.smarttab = true
-- vim.opt.tabstop = 4
-- vim.opt.softtabstop = 4
-- }}}
-- Indent {{{2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
-- }}}
-- Visual Block {{{2
vim.opt.virtualedit = 'block'
-- }}}
-- Disable &paste on entering Normal mode {{{
vim.api.nvim_create_autocmd('ModeChanged', {
  group = 'MyAutoCmd',
  pattern = '*:n',
  callback = function()
    if vim.o.paste then
      vim.opt_local.paste = false
      vim.notify('nopaste')
    end
    if vim.wo.diff then
      vim.cmd('diffupdate')
    end
  end,
})
-- }}}
-- }}}

-- FILETYPE {{{1
-- See lua/hooks/ft.lua for each filetype settings
-- syntax max column
vim.opt.synmaxcol = 300
-- Diff{{{
vim.opt.diffopt = 'internal,algorithm:patience,indent-heuristic'
-- See `filetype.lua`; `Disable paste and update diff when ModeChanged`
-- }}}
-- }}}

-- HISTORY, BACKUP, SWAPFILE{{{1
vim.opt.history = 200
vim.opt.shada = "'100,<20,s10,h,r/tmp/,rterm:"
-- Undo file{{{
vim.opt.undofile = true
vim.o.undodir = vim.o.directory
-- }}}
-- Backup and SWAP{{{
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
-- Remove current dir from swap
vim.opt.directory:remove('.')
vim.opt.backupdir:remove('.')
-- }}}
-- }}}

-- SEARCH {{{1
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false
vim.opt.wrapscan = true
vim.opt.isfname:append('@-@')
vim.opt.isfname:remove('==')
-- }}}

-- MAPPINGS {{{1
-- See lua/mappings.lua for each mappings
-- Keymapping timeout.
vim.opt.timeout = true
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 100

-- CursorHold time.
vim.opt.updatetime = 1000
-- }}}

-- ==========================================================================
-- colorscheme
-- ==========================================================================
vim.opt.termguicolors = true
vim.opt.inccommand = 'nosplit'
-- vim.opt.winblend = 20
-- vim.opt.pumblend = 20

vim.cmd([[
  highlight NonText guibg=none
  highlight Normal guibg=none
]])
-- highlight NormalNC guibg=none
--  highlight Normal ctermbg=none
--  highlight NonText ctermbg=none
--  highlight NormalSB guibg=none

