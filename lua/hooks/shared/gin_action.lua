-- Gin action chooser: replace gin's `a` (`<Plug>(gin-action-choice)`) with a
-- ddu fuzzy finder over the buffer-local `<Plug>(gin-action-*)` mappings.
--
-- Used by after/ftplugin/gin-{log,branch,reflog,stash,status,tag}.lua.
-- Sourced after gin's own ftplugin/gin-*.vim (after/ dir comes later on the
-- runtimepath), so this `a` mapping deterministically wins over gin's
-- `map <buffer> a <Plug>(gin-action-choice)`.
--
-- Same idea as the Telescope version in
-- https://blog.atusy.net/2024/03/15/instant-fixup-with-gin-vim/
-- The picker is the custom ddu source `gin_action`
-- (denops/@ddu-sources/gin_action).

local M = {}

function M.setup()
  vim.keymap.set("n", "a", function()
    -- Collect `<Plug>(gin-action-*)` mappings like gin#action#list() does.
    local items = {}
    for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
      local name = (m.lhs or ""):match("^<Plug>%(gin%-action%-(.-)%)$")
      if name ~= nil then
        table.insert(items, {
          word = name,
          action = { mapping = m.lhs },
        })
      end
    end
    if vim.tbl_isempty(items) then
      vim.notify("No <Plug>(gin-action-*) mappings found", vim.log.levels.WARN)
      return
    end
    table.sort(items, function(x, y)
      return x.word < y.word
    end)
    local split = vim.fn.has("nvim") == 1 and "floating" or "horizontal"
    vim.fn["ddu#start"]({
      name = "gin_action",
      sources = {
        {
          name = "gin_action",
          options = { defaultAction = "do" },
          params = { items = items },
        },
      },
      uiParams = {
        ff = {
          split = split,
        },
      },
    })
  end, { buffer = true, nowait = true, desc = "Gin: choose action (ddu)" })
end

return M
