-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#flexible-components
-- Flexible WorkDir: full path -> shortened path -> hidden

local WorkDir = {
    init = function(self)
        self.icon = (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. " "
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~")
    end,
    hl = { fg = "blue", bold = true },

    flexible = 1,

    {
        -- evaluates to the full-length path
        provider = function(self)
            local trail = self.cwd:sub(-1) == "/" and "" or "/"
            return self.icon .. self.cwd .. trail .. " "
        end,
    },
    {
        -- evaluates to the shortened path
        provider = function(self)
            local cwd = vim.fn.pathshorten(self.cwd)
            local trail = self.cwd:sub(-1) == "/" and "" or "/"
            return self.icon .. cwd .. trail .. " "
        end,
    },
    {
        -- evaluates to "", hiding the component
        provider = "",
    }
}

return WorkDir
