vim.opt.number = true

-- History (command-line history count)
vim.opt.history = 100

-- Persistent undo (keep undo history across restarts)
vim.opt.undofile = true

-- No swap files
vim.opt.swapfile = false

-- Clipboard
-- Priority: clip script (OSC52+file) > native GUI tool > OSC 52 fallback
local function has_native_clipboard()
  return (vim.fn.executable('xsel') == 1 and vim.env.DISPLAY)
      or (vim.fn.executable('xclip') == 1 and vim.env.DISPLAY)
      or (vim.fn.executable('wl-copy') == 1 and vim.env.WAYLAND_DISPLAY)
      or vim.fn.executable('termux-clipboard-set') == 1
end

if vim.fn.executable('clip') == 1 then
  -- TODO: FIND MUCH BETTER WAY TO USE CLIPBOARD WITH CLI
  -- CUSTOM `CLIP` command
  -- clip script: OSC 52 copy + file-based paste (herdr / terminal env)
  vim.g.clipboard = {
    name = 'clip',
    copy = {
      ['+'] = 'clip -i',
      ['*'] = 'clip -i',
    },
    paste = {
      ['+'] = 'clip -o',
      ['*'] = 'clip -o',
    },
    cache_enable = false,
  }
elseif has_native_clipboard() then
  vim.opt.clipboard:append('unnamedplus')
else
  -- OSC 52 fallback (built-in Neovim 0.10+)
  local ok, osc52 = pcall(require, 'vim.ui.clipboard')
  if ok and osc52.osc52_copy then
    vim.g.clipboard = {
      name = 'OSC 52',
      copy = {
        ['+'] = osc52.osc52_copy('+'),
        ['*'] = osc52.osc52_copy('*'),
      },
      paste = {
        ['+'] = osc52.osc52_paste('+'),
        ['*'] = osc52.osc52_paste('*'),
      },
    }
  end
end

