-- Filetype plugin for dpp.vim hooks files (*.dpp): Lua-like editing.
-- See .agents/issues/dpp-filetype.md

-- Lua-ish indentation (mirror the `lua` entry in lua/hooks/ft.dpp)
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2
vim.bo.expandtab = true

-- Lua-style comments
vim.bo.commentstring = '-- %s'

-- ---------------------------------------------------------------------------
-- Folding: 
--
-- Two levels combined in one 'foldexpr':
--   1. hook blocks (`-- name {{{` ... `-- }}}`) -> base level from markers
--   2. Lua structure *inside* the blocks (function/if/for/while/do bodies)
--      -> treesitter (`vim.treesitter.foldexpr()`, lua parser)
--
-- Nothing folds outside the hook blocks, and the hook blocks themselves keep
-- folding exactly as before (`zM`/`zR` still work).
-- ---------------------------------------------------------------------------

-- Map filetype `dpp` to the lua parser so the built-in treesitter fold
-- machinery works on this buffer.
vim.treesitter.language.register('lua', 'dpp')
--vim.treesitter.language.register('lua', 'dpp', 'viml')

-- Treesitter highlighting: whole file parses as lua, so hook markers are
-- plain comments and LuaDoc annotations inside comments get highlighted via
-- the `luadoc` injection (queries shipped by tree-sitter-manager.nvim).
-- This is the primary highlighting path — kakehashi semantic tokens are
-- disabled for dpp buffers (plugins/kakehashi.nvim, plugin/kakehashi.lua), preferring
-- treesitter to LSP semantic tokens:
-- https://blog.atusy.net/2025/07/15/prefer-luadoc-to-luals-semantictokens
if vim.treesitter.language.add('lua') then
  vim.treesitter.start()
end

-- Marker base level per line (1 = inside a hook block, 0 = outside), cached
-- per buffer. Mirrors dpp's hooksFileMarker semantics, incl. nested markers.
local cache = {} -- bufnr -> { [lnum] = base }

local function compute_markers(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local lvl = {}
  local depth = 0
  for i, line in ipairs(lines) do
    local opens = line:match('^%-%-.*{{{%s*$') ~= nil
    local closes = line:match('^%-%-.*}}}%s*$') ~= nil
    if opens and closes then
      lvl[i] = depth
    elseif opens then
      depth = depth + 1
      lvl[i] = depth
    elseif closes then
      lvl[i] = depth
      depth = math.max(depth - 1, 0)
    else
      lvl[i] = depth
    end
  end
  cache[buf] = lvl
end

---foldexpr for `*.dpp` files.
---`vim.treesitter.foldexpr()` returns '0'..'9' (absolute) or '>N' (absolute
---level N with a fold-start marker); add the marker base in both cases.
---@param lnum integer
---@return string
local function foldexpr(lnum)
  local buf = vim.api.nvim_get_current_buf()
  local lvl = cache[buf]
  if not lvl then
    compute_markers(buf)
    lvl = cache[buf]
  end

  local ts = vim.treesitter.foldexpr(lnum)
  local base = lvl[lnum] or 0
  if base == 0 then
    return ts
  end
  local prefix, num = ts:match('^(%D?)(%d+)$')
  local level = (tonumber(num) or 0) + base
  if prefix == '' then
    return tostring(level)
  end
  return prefix .. tostring(level)
end

_G.__dpp_fold = foldexpr

-- Invalidate the marker cache while editing.
vim.api.nvim_create_autocmd(
  { 'TextChanged', 'TextChangedI', 'BufWritePost' },
  { buffer = 0, callback = function()
    cache[vim.api.nvim_get_current_buf()] = nil
  end }
)

vim.opt_local.foldmethod = 'expr'
vim.opt_local.foldexpr = 'v:lua.__dpp_fold(v:lnum)'
vim.opt_local.foldlevelstart = 99

