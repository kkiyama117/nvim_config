vim.opt.number = true

-- History (command-line history count)
vim.opt.history = 100

-- Persistent undo (keep undo history across restarts)
vim.opt.undofile = true

-- No swap files
vim.opt.swapfile = false

-- Clipboard (only if a clipboard tool is actually available)
-- Avoid error???
local has_clipboard = (vim.fn.executable('xsel') == 1 and vim.env.DISPLAY)
    or (vim.fn.executable('xclip') == 1 and vim.env.DISPLAY)
    or (vim.fn.executable('wl-copy') == 1 and vim.env.WAYLAND_DISPLAY)
    or vim.fn.executable('termux-clipboard-set') == 1
    or (vim.fn.executable('tmux') == 1 and vim.env.TMUX)
if has_clipboard then
  vim.opt.clipboard:append('unnamedplus')
end


