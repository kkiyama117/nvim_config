-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#spell

local Spell = {
    condition = function()
        return vim.wo.spell
    end,
    provider = 'SPELL ',
    hl = { bold = true, fg = "orange" }
}

return Spell
