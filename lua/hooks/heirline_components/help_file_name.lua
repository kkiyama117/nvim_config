-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#help-filename

local HelpFileName = {
    condition = function()
        return vim.bo.filetype == "help"
    end,
    provider = function()
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.fnamemodify(filename, ":t")
    end,
    hl = { fg = "blue" },
}

return HelpFileName
