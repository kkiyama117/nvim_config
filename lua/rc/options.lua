-- import
local utils = require('utils')

-----------------------------------------------------------------------------
-- clipboard with system
-----------------------------------------------------------------------------
vim.opt.clipboard = "unnamedplus,unnamed"
-- secure exrc
vim.opt.secure = true

-----------------------------------------------------------------------------
-- BACKUP
-----------------------------------------------------------------------------
--" no swap, auto save, and have history
vim.opt.swapfile = false
vim.opt.autowrite = true
vim.opt.undofile = true

-----------------------------------------------------------------------------
-- special characters
-----------------------------------------------------------------------------
-- backspace alternative
vim.opt.backspace = "indent,eol,start"

-- tab and shift config
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.listchars:prepend('tab:»-')
vim.opt.listchars = { tab = '»-', trail = '-', eol = '↲', extends = '»', precedes = '«', nbsp = '+' }
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftround = true

-----------------------------------------------------------------------------
-- Encoding and format:
-----------------------------------------------------------------------------
vim.opt.matchpairs:append("<:>")
vim.opt.spelllang = "en,jp"
vim.opt.helplang = "jp,en"

vim.opt.fileformat = 'unix'
vim.opt.fileformats = 'unix,dos,mac'
vim.opt.foldmethod = "indent"

-----------------------------------------------------------------------------
-- Window and tab style
-----------------------------------------------------------------------------
--" vertical split
vim.opt.splitright = true
--" Show title.
vim.opt.title = true
vim.opt.titlelen = 95
--" Always display the tabline, even if there is only one tab
vim.opt.showtabline = 2 --0
-- status line and command line
vim.opt.laststatus = 3

-----------------------------------------------------------------------------
-- Search and menu bar:
-----------------------------------------------------------------------------
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.wrapscan = true
vim.opt.whichwrap = "b,s,[,],<,>"

-- wild menu
vim.opt.wildmode:append('longest')
vim.opt.wildmode:append('list')

vim.opt.completeopt = 'menuone,noinsert,preview'

-----------------------------------------------------------------------------
-- TRUE COLOR SETTINGS:
-----------------------------------------------------------------------------
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1
vim.opt.termguicolors = true
-- TODO: 仮置き
-- transparent background
vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
--vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
--vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'none' })
--vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'none' })
if utils.isNvim() then
  --set pumblend=0
  vim.opt.pumheight = 15
  vim.opt.inccommand = 'split'
end
vim.opt.winblend = 20
vim.cmd([[ let &t_8f="\<Esc>[38;2;%lu;%lu;%lum" ]])
vim.cmd([[ let &t_8b="\<Esc>[48;2;%lu;%lu;%lum" ]])


-----------------------------------------------------------------------------
-- Base Appearance
-----------------------------------------------------------------------------
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.showmatch = true
vim.opt.matchtime = 100 -- showmatch time
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 5
vim.opt.signcolumn = "yes"

-- bell
vim.opt.visualbell = true

-- Cursol shape style
vim.opt.guicursor = "n-v-c:block-blinkwait700-blinkoff400-blinkon250,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor"
vim.opt.cursorlineopt = 'number'

-----------------------------------------------------------------------------
-- Fonts
-----------------------------------------------------------------------------
vim.opt.guifont:prepend("PlemolJP35 Console NF Regular 16")

