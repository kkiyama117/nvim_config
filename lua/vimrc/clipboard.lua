vim.o.clipboard = 'unnamedplus'

-- Option 3: keep the default (auto-detected) clipboard provider so paste works
-- natively when a clipboard tool exists (xclip/wl-copy/tmux/osc52), and
-- additionally broadcast every yank to the terminal clipboard via OSC 52
-- (works over SSH/tmux where no native clipboard is available).
--   https://github.com/neovim/neovim/discussions/28010#discussioncomment-9529001
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('osc52_copy', { clear = true }),
  callback = function()
    -- Read the unnamed register (""): preserves the trailing newline that
    -- vim.v.event.regcontents drops on `yy`, and does NOT trigger the
    -- clipboard provider (getreg('+') would, causing the OSC 52 hang).
    local text = vim.fn.getreg('')
    if text == '' then
      return
    end
    local lines = vim.split(text, '\n', { plain = true })
    require('vim.ui.clipboard.osc52').copy('+')(lines)
  end,
})
