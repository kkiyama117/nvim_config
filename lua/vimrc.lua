-- VIMRC MODULE (to define functions)
local M = {}
-- TODO: Add `on_filetype()` function

-- Toggle option function (with mapping in `lua/mappings.lua`){{{
function M.toggle_option(name)
  if name == 'laststatus' then
    local cur = vim.opt_local.laststatus:get()
    vim.opt_local.laststatus = cur == 0 and 2 or 0
  else
    vim.opt_local[name] = not vim.opt_local[name]:get()
  end
  vim.notify(string.format('%s=%s', name, vim.inspect(vim.opt_local[name]:get())))
end

function M.toggle_conceal()
  local cur = vim.opt_local.conceallevel:get()
  vim.opt_local.conceallevel = cur == 0 and 3 or 0
  vim.notify(string.format('conceallevel=%s', vim.inspect(vim.opt_local.conceallevel:get())))
end
-- }}}

-- Diag location list{{{
function M.diagnostics_to_location_list()
  if not vim.fn.has('nvim') then
    return
  end

  local current = vim.fn.fnamemodify(vim.fn.bufname('%'), ':p')
  local qflist = vim
    .iter(vim.diagnostic.get())
    :filter(function(d)
      local bufname = vim.fn.bufname(d.bufnr)
      return vim.fn.fnamemodify(bufname, ':p') == current
    end)
    :map(function(d)
      return {
        bufnr = d.bufnr,
        lnum = d.lnum + 1,
        col = d.col + 1,
        text = d.message,
      }
    end)
    :totable()

  if vim.tbl_isempty(qflist) then
    vim.cmd('lclose')
  else
    vim.fn.setloclist(vim.fn.win_getid(), qflist)
    vim.cmd('lopen')
  end
end
-- }}}

-- Append staged git diff as comments to current buffer{{{
function M.append_diff()
  local git_root = vim.fn.fnamemodify(vim.fn.finddir('.git', '.;'), ':h')
  if git_root == '' then
    return
  end

  local diff = vim.fn.system('git -C ' .. vim.fn.shellescape(git_root) .. ' diff --cached')
  if diff == '' then
    return
  end

  local lines = vim.split(diff, '\n')
  -- Take first 200 lines and prefix with '# '
  local comment_lines = vim
    .iter(lines)
    :take(200)
    :map(function(line)
      return '# ' .. line
    end)
    :totable()

  vim.fn.append(vim.fn.line('$'), comment_lines)
end
-- }}}

return M

