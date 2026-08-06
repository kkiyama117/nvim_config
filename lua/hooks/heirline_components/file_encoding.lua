-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#filetype-fileencoding-and-fileformat

local FileEncoding = {
    provider = function()
        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
        return enc ~= 'utf-8' and enc:upper()
    end
}

return FileEncoding
