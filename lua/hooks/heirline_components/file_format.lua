-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#filetype-fileencoding-and-fileformat

local FileFormat = {
    provider = function()
        local fmt = vim.bo.fileformat
        return fmt ~= 'unix' and fmt:upper()
    end
}

return FileFormat
