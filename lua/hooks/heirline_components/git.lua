local conditions = require("heirline.conditions")

-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#git
-- Uses gitsigns.nvim (`vim.b.gitsigns_status_dict`)
local Git = {
    condition = conditions.is_git_repo,

    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict or {}
        self.has_changes = (self.status_dict.added or 0) ~= 0
            or (self.status_dict.removed or 0) ~= 0
            or (self.status_dict.changed or 0) ~= 0
    end,

    update = { "User", pattern = "GitSignsUpdate" },

    hl = { fg = "orange" },

    {   -- git branch name
        provider = function(self)
            return self.status_dict.head and (" " .. self.status_dict.head) or ""
        end,
        hl = { bold = true }
    },
    -- You could handle delimiters, icons and counts similar to Diagnostics
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = "("
    },
    {
        provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("+" .. count)
        end,
        hl = { fg = "git_add" },
    },
    {
        provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("-" .. count)
        end,
        hl = { fg = "git_del" },
    },
    {
        provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("~" .. count)
        end,
        hl = { fg = "git_change" },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = ")",
    },
}

return Git
