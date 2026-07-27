-- Lua port of Shougo's `vim/autoload/job.vim` (shougo-s-github).
--
-- Synchronous-looking command runner that never blocks longer than a timeout:
-- stdout and stderr are merged in arrival order, `\r\n` is normalised to `\n`,
-- and the exit code is kept aside in `status()` instead of `v:shell_error`.

local M = {}

-- Same 1000ms bound as `job#system()`; a hung command returns partial output
-- instead of freezing the caller (ddt-ui-shell evaluates its prompt through it).
local DEFAULT_TIMEOUT = 1000

local last_status = 0

local function to_argv(cmd)
  if type(cmd) == 'table' then
    return cmd
  end

  local argv = vim.split(vim.o.shell, ' ', { trimempty = true })
  vim.list_extend(argv, vim.split(vim.o.shellcmdflag, ' ', { trimempty = true }))
  table.insert(argv, cmd)
  return argv
end

---Run `cmd` and return its merged stdout/stderr.
---@param cmd string|string[] Argv list, or a string run through `'shell'`.
---@param opts? { timeout?: integer, cwd?: string, env?: table<string,string> }
---@return string
function M.system(cmd, opts)
  opts = opts or {}

  local chunks = {}
  local function collect(_, data)
    if data then
      chunks[#chunks + 1] = data
    end
  end

  local ok, proc = pcall(vim.system, to_argv(cmd), {
    text = true,
    cwd = opts.cwd,
    env = opts.env,
    stdout = collect,
    stderr = collect,
  })
  if not ok then
    last_status = -1
    return ''
  end

  local completed = proc:wait(opts.timeout or DEFAULT_TIMEOUT)
  last_status = completed and completed.code or -1

  return (table.concat(chunks):gsub('\r\n', '\n'))
end

---Exit code of the last `system()` call; 124 on timeout, -1 on spawn failure.
---@return integer
function M.status()
  return last_status
end

return M
