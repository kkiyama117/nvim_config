-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#terminal-name

local TerminalName = {
    condition = function()
        return vim.bo.buftype == 'terminal'
    end,
    provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
        return " " .. tname
    end,
    hl = { fg = "blue", bold = true },
}

return TerminalName
