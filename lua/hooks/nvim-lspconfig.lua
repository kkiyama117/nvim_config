-- lua_source {{{
-- NOTE: Disable lsp watcher. Too slow on linux
-- https://github.com/neovim/neovim/issues/23725#issuecomment-1561364086
require('vim.lsp._watchfiles')._watchfunc = function()
  return function() end
end

vim.diagnostic.config({
  update_in_insert = false,
  virtual_text = {
    severity = {
      min = 'WARN',
    },
    severity_sort = true,
    format = function(diagnostic)
      if diagnostic.code then
        return string.format('%s (%s: %s)', diagnostic.message, diagnostic.source, diagnostic.code)
      else
        return string.format('%s (%s)', diagnostic.message, diagnostic.source)
      end
    end,
  },
})

-- Format on save via LSP `textDocument/formatting`.
-- Uses Neovim builtin `vim.lsp.buf.format` (sync within BufWritePre).
-- Skips buffers with no attached client supporting formatting, so
-- non-LSP filetypes and servers without formatting are left untouched.
local format_grp = vim.api.nvim_create_augroup('LspFormatOnSave', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = format_grp,
  callback = function(args)
    -- Lua files are handled by StyLua, skip LSP formatting
    if vim.bo[args.buf].filetype == 'lua' then
      return
    end
    -- LSP formatting
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = args.buf })) do
      if client:supports_method('textDocument/formatting', { bufnr = args.buf }) then
        vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 1000, async = false })
        return
      end
    end
  end,
})

-- StyLua formatter for Lua files (external command, not LSP).
-- LSP formatting is skipped for Lua files, so StyLua always runs when installed.
local stylua_grp = vim.api.nvim_create_augroup('StyLuaFormatOnSave', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = stylua_grp,
  pattern = '*.lua',
  callback = function(args)
    local stylua = vim.fn.executable('stylua')
    if stylua == 1 then
      local bufnr = args.buf
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local input = table.concat(lines, '\n')
      if #input == 0 then
        return
      end

      local result =
        vim.fn.system('stylua --stdin-filepath ' .. vim.fn.shellescape(vim.api.nvim_buf_get_name(bufnr)) .. ' -', input)
      if vim.v.shell_error == 0 and result ~= '' then
        local new_lines = vim.split(result, '\n', { plain = true })
        -- stylua always adds a trailing newline; remove the extra empty line
        if #new_lines > 0 and new_lines[#new_lines] == '' then
          table.remove(new_lines)
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, new_lines)
      end
    end
  end,
})

-- Ensure the file ends with exactly one empty line.
-- Runs after all other formatters (LSP, StyLua) to guarantee a trailing newline
-- followed by a blank line, which many linters and POSIX tools expect.
local trailing_newline_grp = vim.api.nvim_create_augroup('TrailingNewlineOnSave', { clear = true })
vim.api.nvim_create_autocmd('BufWritePre', {
  group = trailing_newline_grp,
  callback = function(args)
    local bufnr = args.buf
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines == 0 then
      return
    end
    -- Remove all trailing empty lines, then add exactly one
    while #lines > 0 and lines[#lines] == '' do
      table.remove(lines)
    end
    table.insert(lines, '')
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end,
})
-- }}}
