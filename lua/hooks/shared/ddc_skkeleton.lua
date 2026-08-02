-- lua_source {{{
-- Save current ddc config and patch with skkeleton sources
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-enable-pre',
  group = 'MyAutoCmd',
  callback = function()
    if vim.b.prev_buffer_skkeleton_config ~= nil then
      return
    end

    -- Overwrite sources
    vim.b.prev_buffer_skkeleton_config = vim.fn['ddc#custom#get_buffer']()

    vim.fn['ddc#custom#patch_buffer']({
      cmdlineSources = {
        'skkeleton',
        'skkeleton_okuri',
      },
      sources = {
        'around',
        'skkeleton',
        'skkeleton_okuri',
        'line',
      },
      sourceOptions = {
        _ = {
          keywordPattern = '[ァ-ヮア-ンー]+',
        },
      },
    })
  end,
})

-- Restore previous ddc config
vim.api.nvim_create_autocmd('User', {
  pattern = 'skkeleton-disable-post',
  group = 'MyAutoCmd',
  callback = function()
    if vim.b.prev_buffer_skkeleton_config ~= nil then
      -- Restore sources
      vim.fn['ddc#custom#set_buffer'](vim.b.prev_buffer_skkeleton_config)
      vim.b.prev_buffer_skkeleton_config = nil
    end
  end,
})

