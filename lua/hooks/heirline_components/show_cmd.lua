-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#no-cmdheight-no-problem-searchcount-macrorec-and-showcmd

local ShowCmd = {
    condition = function()
        return vim.o.cmdheight == 0
    end,
    provider = ":%3.5(%S%)",
}

return ShowCmd
