-- https://github.com/stevearc/overseer.nvim/blob/master/doc/third_party.md#heirline

local utils = require('heirline.utils')

local Spacer = { provider = ' ' }

-- Wrap a child so it is always followed by a spacer, and hidden together
-- with its own condition.
local function rpad(child)
  return {
    condition = child.condition,
    child,
    Spacer,
  }
end

local function tasks_for_status(status)
  return {
    condition = function(self)
      return self.tasks[status]
    end,
    provider = function(self)
      return string.format('%s%d', self.symbols[status], #self.tasks[status])
    end,
    hl = function()
      return {
        fg = utils.get_highlight(string.format('Overseer%s', status)).fg,
      }
    end,
  }
end

local Overseer = {
  condition = function()
    return package.loaded.overseer
  end,
  init = function(self)
    local tasks = require('overseer.task_list').list_tasks({
      unique = true,
      include_ephemeral = true,
    })
    self.tasks = require('overseer.util').tbl_group_by(tasks, 'status')
  end,
  static = {
    symbols = {
      ['CANCELED'] = ' ',
      ['FAILURE'] = '󰅚 ',
      ['SUCCESS'] = '󰄴 ',
      ['RUNNING'] = '󰑮 ',
    },
  },

  rpad(tasks_for_status('CANCELED')),
  rpad(tasks_for_status('RUNNING')),
  rpad(tasks_for_status('SUCCESS')),
  rpad(tasks_for_status('FAILURE')),
}

return Overseer
