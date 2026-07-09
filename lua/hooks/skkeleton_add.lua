local M = {}

vim.g['skkeleton#debug'] = true

-----------------------------------------------------------------------------
-- autocmd
-----------------------------------------------------------------------------
vim.api.nvim_create_autocmd({'User'}, {
  pattern = 'skkeleton-initialize-pre',
  once = true,
  nested = true,
  callback =
    function()
      skkeleton_init()
    end
})

-----------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------
vim.api.nvim_create_autocmd({'User'}, {
  pattern = 'skkeleton-enable-pre',
  callback =
    function()
    -- Overwrite sources and use native
      M.prev_buffer_config = vim.fn['ddc#custom#get_buffer']()
      vim.fn['ddc#custom#patch_buffer']({
        ui='native',
        sources={'around','skkeleton'},
        sourceOptions={
          _={
            keywordPattern= '[ァ-ヮア-ンー]+',
          },
        },
      })
    -- Update key
    set_key_ui_native()
    end
})

vim.api.nvim_create_autocmd({'User'}, {
  pattern = 'skkeleton-disable-pre',
  callback =
    function()
      -- Restore
      if M.prev_buffer_config ~= nil then
        vim.fn['ddc#custom#set_buffer'](M.prev_buffer_config)
      end
    end
})

vim.cmd("imap <C-j> <Plug>(skkeleton-toggle)")
--vim.keymap.set({'i','c','t'}, '<C-j>', [[<Plug>(skkeleton-toggle)]], { remap = true })

----------------------------------------------------------------------------
local function skkeleton_init()
  vim.notify("LOAD SKKELETON")

  -- Back space backward
  vim.fn['skkeleton#register_keymap']('henkan', '<BS>', 'henkanBackward')
  vim.fn['skkeleton#register_keymap']('henkan', '<C-h>', 'henkanBackward')
  vim.fn['skkeleton#register_keymap']('henkan', 'x','')
  vim.fn['skkeleton#register_keymap']('input', '/', 'abbrev')
  vim.fn['skkeleton#register_kanatable']('rom',{
        ['z1'] = {'①', ''},
        ['z2'] = {'②', ''},
        ['z3'] = {'③', ''},
        ['z4'] = {'④', ''},
        ['z5'] = {'⑤', ''},
        ['z6'] = {'⑥', ''},
        ['z7'] = {'⑦', ''},
        ['z8'] = {'⑧', ''},
        ['z9'] = {'⑨', ''},
  })

  -- skkeleton config
  vim.fn['skkeleton#config']({
    completionRankFile = vim.fs.joinpath(vim.env.XDG_CACHE_HOME,'dpp','skkeleton.rank.hkson'),
    eggLikeNewline = true,
    keepState = false,
    sources = {'skk_server'},
    userDictionary = vim.fs.joinpath(vim.env.XDG_CACHE_HOME,'dpp','.skkeleton'),
  })
end

-----------------------------------------------------------------------------
-- General
-----------------------------------------------------------------------------
-- Completion Key (for ui-native)
local function set_key_ui_native()
  vim.keymap.set({'i'}, '<TAB>', function()
    if vim.fn.pumvisible() then
      return '<C-n>'
    elseif vim.fn.col('.') <= 1 or vim.fn.getline('.')[vim.fn.col('.')-2] ~= '\\s' then
      return '<TAB>'
    else
      vim.fn['ddc#map#manual_complete']()
    end
  end, {expr = true})

  vim.keymap.set({'i'}, '<S-TAB>', function()
    if vim.fn.pumvisible() then return '<C-p>' else return '<C-h>' end
  end, {expr = true})
end

return M

