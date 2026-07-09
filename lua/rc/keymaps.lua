vim.keymap.set('n', '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = " "

--local function t(str)
--  return vim.api.nvim_replace_termcodes(str, true, true, true)
--end

local function my_magic_exit()
  if vim.fn.winnr('$') > 2 then
    vim.notify("close")
    vim.cmd('close')
  elseif vim.fn.tabpagenr('$') > 1 then
    vim.cmd('tabclose')
  else
    vim.cmd('qa')
  end
end

local au_keymap = vim.api.nvim_create_augroup('general_key', { clear = true })
-----------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------
--- Set No operator keymaps
local function disable_mappings()
  vim.keymap.set('n', 'Q', '<Nop>')
  vim.keymap.set('n', '<Left>', '<Nop>')
  vim.keymap.set('n', '<Down>', '<Nop>')
  vim.keymap.set('n', '<Up>', '<Nop>')
  vim.keymap.set('n', '<Right>', '<Nop>')
end

local function change_mappings()
  -----------------------------------------------------------------------------
  -- Exit with MapLeader
  -----------------------------------------------------------------------------
  vim.keymap.set('n', '[Exit]', '<Nop>')
  vim.keymap.set('n', '<Leader>q', '[Exit]', { remap = true })
  vim.keymap.set('n', '<Plug>(my_magic_exit)', my_magic_exit,
    { silent = true, desc = 'exit if only one window is opened' })
  vim.keymap.set('n', '[Exit]q', '<Plug>(my_magic_exit)', { remap = true })
  vim.keymap.set('n', '[Exit]a', ':<C-u>qa<CR>', {})
  vim.keymap.set('n', '[Exit]w', function()
    vim.cmd('w')
    my_magic_exit()
    return ''
  end, { remap = true })

  -----------------------------------------------------------------------------
  -- window
  -----------------------------------------------------------------------------
  vim.keymap.set('n', '[Window]', '<Nop>')
  vim.keymap.set('n', '<Leader>w', '[Window]', { remap = true })
  vim.keymap.set('n', '[Window]h', ':<C-u>wincmd h<CR>', { silent = true })
  vim.keymap.set('n', '[Window]j', ':<C-u>wincmd j<CR>', { silent = true })
  vim.keymap.set('n', '[Window]k', ':<C-u>wincmd k<CR>', { silent = true })
  vim.keymap.set('n', '[Window]l', ':<C-u>wincmd l<CR>', { silent = true })
  vim.keymap.set('n', '[Window]p', ':<C-u>wincmd p<CR>', { silent = true })
  vim.keymap.set('n', '[Window]P', ':<C-u>wincmd P<CR>', { silent = true })
  vim.keymap.set('n', '[Window]w', ':<C-u>wincmd w<CR>', { silent = true })
  vim.keymap.set('n', '[Window]W', ':<C-u>wincmd W<CR>', { silent = true })
  vim.keymap.set('n', '[Window]q', ':<C-u>q<CR>', { silent = true })

  -----------------------------------------------------------------------------
  -- Others
  -----------------------------------------------------------------------------
  -- Escape terminal
  vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', {})
  -- Paste and move last character
  vim.keymap.set({ 'n', 'v' }, 'p', 'p`]', { silent = true })
  vim.keymap.set({ 'v' }, 'y', 'y`]', { silent = true })
end

------------------------------------------------------------------------------
-- AutoCmd
------------------------------------------------------------------------------

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  pattern = "*",
  group = au_keymap,
  --command = [[  ]]
  callback =
      function()
        disable_mappings()
        change_mappings()
      end
})

-- 仮置き
vim.keymap.set('n', '<Leader>de', '[Dark]', { remap = true })
--vim.cmd("nmap <Leader>de \[Dark\]")

