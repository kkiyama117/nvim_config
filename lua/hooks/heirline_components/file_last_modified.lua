-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#filesize-and-filelastmodified

local FileLastModified = {
    -- did you know? Vim is full of functions!
    provider = function()
        local ftime = vim.fn.getftime(vim.api.nvim_buf_get_name(0))
        return (ftime > 0) and os.date("%c", ftime)
    end
}

return FileLastModified
