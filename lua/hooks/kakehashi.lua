-- lua_source {{{
  vim.lsp.config.kakehashi = {
    cmd = { 'kakehashi' },
    init_options = { autoInstall = true },
    on_attach = function(_, bufnr)
      -- Let kakehashi own highlighting (avoids double-highlighting)
      vim.api.nvim_create_autocmd('LspTokenUpdate', {
        buffer = bufnr,
        once = true,
        callback = function()
          vim.opt_local.syntax = 'OFF'
          vim.treesitter.stop(bufnr)
        end,
      })
    end,
  }

  vim.lsp.enable('kakehashi')
-- }}}
