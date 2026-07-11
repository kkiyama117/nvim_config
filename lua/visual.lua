-- options for looks of neovim
--
vim.opt.termguicolors = true
vim.opt.winblend = 90 -- ウィンドウの不透明度
vim.opt.pumblend = 90 -- ポップアップメニューの不透明度
vim.cmd([[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
  highlight NormalNC guibg=none
  highlight NormalSB guibg=none
]])
