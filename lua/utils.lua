------------------------------------------------------------------------------
-- Utils
------------------------------------------------------------------------------
local M = {}

function M.gather_check_files()
    local glob_patterns = {
        "**/*.lua",
        "**/*.toml",
        "**/*.ts",
    }
    local target_directories = vim.iter({ vim.g.base_dir, vim.fn.expand("~/.config/nvim") }):join(",")
    local check_files = {}
    for _, glob_pattern in pairs(glob_patterns) do
        table.insert(check_files, vim.fn.globpath(target_directories, glob_pattern, true, true))
    end
    return vim.iter(check_files):flatten():totable()
end

--"---------------------------------------------------------------------------
--" LOAD PLUGIN
--"---------------------------------------------------------------------------

function M.load_plugin(name)
  -- load plenary if exists
  local ok, module = pcall(require, name)
  if not ok then
    -- not loaded
    return false, nil
  else
    -- loaded
    return true, module
  end
end

--"---------------------------------------------------------------------------
--" CHECK IF WINDOWS OR NOT:
--"---------------------------------------------------------------------------
function M.isWindows()
  local is_windows = vim.fn['has']('win32') or vim.fn['has']('win64')
  return is_windows ~= 0
end

--"---------------------------------------------------------------------------
--" CHECK IF NVIM OR NOT:
--"---------------------------------------------------------------------------
function M.isNvim()
  return vim.fn.has("nvim") ~= 0
end

--"---------------------------------------------------------------------------
--" path is dir or not
--"---------------------------------------------------------------------------
function M.is_dir(_path)
  if vim.fn.isdirectory(_path) == 0 then
    return false
  else
    return true
  end
end

function M.merge_dict(t1,t2)
  local merged = {}
  for k,v in pairs(t1) do merged[k]=v end
  for k,v in pairs(t2) do merged[k]=v end
  return merged
end

return M

