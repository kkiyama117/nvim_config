-- Gin buffer source detection.
-- Ported from kyoh86/dotfiles (nvim/lua/kyoh86/lib/gin_buffer_sources.lua).
-- The original parses `ginedit://` bufnames in a denops plugin
-- (denops/gin-buffer-sources); here the parsing is done in pure Lua, so no
-- extra denops plugin is needed.

local M = {}

local cache_vars = {
  "my_gin_scheme",
  "my_gin_worktree",
  "my_gin_params",
  "my_gin_fragment",
  "my_gin_source",
  "my_gin_source_label",
}

-- Percent-decode %XX sequences, keeping the given codes (e.g. "%25") intact.
-- Equivalent to denops-std bufname `decode()`.
local function percent_decode(s, excludes)
  local keep = {}
  for _, e in ipairs(excludes or {}) do
    keep[e:upper()] = true
  end
  return (s:gsub("%%(%x%x)", function(hex)
    local code = "%" .. hex:upper()
    if keep[code] then
      return code
    end
    return string.char(tonumber(hex, 16))
  end))
end

-- Parse `{scheme}://{expr}[;{params}][#{fragment}]` (denops-std bufname format).
-- Params are `key=value` pairs split by `&`; repeated keys become arrays.
local function parse_bufname(bufname)
  local scheme, rest = bufname:match("^(%a+)://(.*)$")
  if not scheme then
    return nil
  end
  -- fragment starts at the first '#', params at the first ';' before it
  local head, fragment = rest:match("^([^#]*)#(.*)$")
  if not head then
    head = rest
  end
  local expr, params_str = head:match("^([^;]*);(.*)$")
  if not expr then
    expr = head
  end
  local params = {}
  if params_str then
    for pair in params_str:gmatch("[^&]+") do
      local key, value = pair:match("^([^=]*)=(.*)$")
      if not key then
        key, value = pair, ""
      end
      key = percent_decode(key)
      value = percent_decode(value)
      if params[key] == nil then
        params[key] = value
      elseif type(params[key]) == "table" then
        table.insert(params[key], value)
      else
        params[key] = { params[key], value }
      end
    end
  end
  return {
    scheme = scheme,
    expr = percent_decode(expr),
    params = params,
    fragment = fragment and percent_decode(fragment) or "",
  }
end

local function source_from_commitish(commitish)
  if not commitish or commitish == "" then
    return "index", "INDEX"
  end
  if commitish == "HEAD" then
    return "head", "HEAD"
  end
  if commitish == ":2" then
    return "ours", "OURS"
  end
  if commitish == ":3" then
    return "theirs", "THEIRS"
  end
  return "revision", commitish
end

local function parse_ginedit(bufname)
  local parsed = parse_bufname(bufname)
  if not parsed or parsed.scheme ~= "ginedit" then
    return nil
  end
  local commitish = parsed.params.commitish
  if type(commitish) == "table" then
    commitish = commitish[1]
  end
  local source, source_label = source_from_commitish(commitish)
  return {
    scheme = "ginedit",
    worktree = parsed.expr,
    params = parsed.params,
    fragment = parsed.fragment,
    source = source,
    source_label = source_label,
  }
end

local function is_ginedit(bufnr)
  return vim.startswith(vim.api.nvim_buf_get_name(bufnr), "ginedit://")
end

local function clear_cache(bufnr)
  local b = vim.b[bufnr]
  if not b then
    return
  end
  for _, name in ipairs(cache_vars) do
    b[name] = nil
  end
end

local function set_cache(bufnr, source)
  local b = vim.b[bufnr]
  b.my_gin_scheme = source.scheme
  b.my_gin_worktree = source.worktree
  b.my_gin_params = source.params
  b.my_gin_fragment = source.fragment
  b.my_gin_source = source.source
  b.my_gin_source_label = source.source_label
end

local function current_tab_diff_windows()
  local wins = {}
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_get_option_value("diff", { win = winid }) then
      table.insert(wins, winid)
    end
  end
  return wins
end

local function path_matches(worktree, fragment, filename)
  if worktree == "" or fragment == "" or filename == "" then
    return false
  end
  local expected = vim.fs.normalize(vim.fs.joinpath(worktree, fragment))
  local actual = vim.fs.normalize(filename)
  return expected == actual
end

local function update_worktree(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].buftype ~= "" then
    return
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  for _, winid in ipairs(current_tab_diff_windows()) do
    local other = vim.api.nvim_win_get_buf(winid)
    if other ~= bufnr and vim.b[other] and vim.b[other].my_gin_scheme == "ginedit" then
      if path_matches(vim.b[other].my_gin_worktree or "", vim.b[other].my_gin_fragment or "", filename) then
        vim.b[bufnr].my_gin_scheme = "file"
        vim.b[bufnr].my_gin_worktree = vim.b[other].my_gin_worktree
        vim.b[bufnr].my_gin_fragment = vim.b[other].my_gin_fragment
        vim.b[bufnr].my_gin_source = "worktree"
        vim.b[bufnr].my_gin_source_label = "WORKTREE"
        return
      end
    end
  end
end

local function update(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if is_ginedit(bufnr) then
    local source = parse_ginedit(vim.api.nvim_buf_get_name(bufnr))
    if source then
      set_cache(bufnr, source)
    else
      clear_cache(bufnr)
    end
    return
  end
  clear_cache(bufnr)
  update_worktree(bufnr)
end

local function update_visible_worktrees()
  for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(winid) then
      local bufnr = vim.api.nvim_win_get_buf(winid)
      if not is_ginedit(bufnr) then
        clear_cache(bufnr)
        update_worktree(bufnr)
      end
    end
  end
end

function M.source_label(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local label = vim.b[bufnr] and vim.b[bufnr].my_gin_source_label
  if label and label ~= "" then
    return label
  end
  return nil
end

function M.setup()
  local group = vim.api.nvim_create_augroup("hooks_gin_buffer_sources", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(ev)
      update(ev.buf)
    end,
  })
end

return M
