-- Filetype plugin for dpp.vim hooks files (*.dpp): Lua-like editing.
-- See .agents/issues/dpp-filetype.md

-- ---------------------------------------------------------------------------
-- Format detection
--
-- dpp hooks files come in two comment styles (the block KIND is set by the
-- hook name, the style by the file's dominant format):
--   lua:  `-- lua_add {{{` / `-- go {{{`  (lua-style comments)
--   viml: `" hook_add {{{` / `" go {{{`  (viml-style comments)
-- The treesitter parser and commentstring follow the detected style.
-- ---------------------------------------------------------------------------
local function detect_format(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, line in ipairs(lines) do
    if line:match('^%s*%-%-%s*[0-9a-zA-Z_-]+%s*{{{%s*$') then
      return 'lua'
    end
    if line:match('^%s*"%s*[0-9a-zA-Z_-]+%s*{{{%s*$') then
      return 'viml'
    end
  end
  return 'lua' -- default
end

local format = detect_format(0)

-- Lua-ish indentation (mirror the `lua` entry in lua/hooks/ft.dpp)
vim.bo.shiftwidth = 2
vim.bo.softtabstop = 2
vim.bo.tabstop = 2
vim.bo.expandtab = true

-- Style-matched comments
vim.bo.commentstring = format == 'viml' and '" %s' or '-- %s'

-- ---------------------------------------------------------------------------
-- Folding: 
--
-- Two levels combined in one 'foldexpr':
--   1. hook blocks (`-- name {{{` / `" name {{{` ... `-- }}}` / `" }}}`)
--      -> base level from markers
--   2. structure *inside* the blocks (function/if/for/while/do bodies)
--      -> treesitter (`vim.treesitter.foldexpr()`, lua or vim parser
--      depending on the detected format)
--
-- Nothing folds outside the hook blocks, and the hook blocks themselves keep
-- folding exactly as before (`zM`/`zR` still work).
-- ---------------------------------------------------------------------------

-- Map filetype `dpp` to the detected parser so the built-in treesitter
-- fold machinery works on this buffer. The parser is passed explicitly to
-- vim.treesitter.start() below because the registration is global: with
-- both lua and vim registered for `dpp`, the last registration would win
-- for implicit resolution.
vim.treesitter.language.register(format == 'viml' and 'vim' or 'lua', 'dpp')
--vim.treesitter.language.register('lua', 'dpp', 'viml')

-- Treesitter highlighting: the whole file parses as the detected language,
-- so hook markers are plain comments and LuaDoc annotations inside comments
-- get highlighted via the `luadoc` injection (queries shipped by
-- tree-sitter-manager.nvim). For viml-format files the vim parser handles
-- the `lua << EOF` heredoc wrapper natively and injects the body as lua.
-- This is the primary highlighting path — kakehashi semantic tokens are
-- disabled for dpp buffers (after/lsp/kakehashi.lua on_attach), preferring
-- treesitter to LSP semantic tokens:
-- https://blog.atusy.net/2025/07/15/prefer-luadoc-to-luals-semantictokens
if vim.treesitter.language.add(format == 'viml' and 'vim' or 'lua') then
  vim.treesitter.start(0, format == 'viml' and 'vim' or 'lua')
end

-- Marker base level per line (1 = inside a hook block, 0 = outside), cached
-- per buffer. Mirrors dpp's hooksFileMarker semantics, incl. nested markers.
-- Both comment styles are recognized: `-- name {{{` (lua) and `" name {{{`
-- (viml).
local cache = {} -- bufnr -> { [lnum] = base }

local function compute_markers(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local lvl = {}
  local depth = 0
  for i, line in ipairs(lines) do
    local opens = line:match('^%s*[%-%"].*{{{%s*$') ~= nil
    local closes = line:match('^%s*[%-%"].*}}}%s*$') ~= nil
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

