-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#filetype-fileencoding-and-fileformat

local utils = require('heirline.utils')

local FileType = {
    provider = function()
        return string.upper(vim.bo.filetype)
    end,
    hl = { fg = utils.get_highlight("Type").fg, bold = true },
}

return FileType
