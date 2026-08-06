-- https://github.com/rebelot/heirline.nvim/blob/master/cookbook.md#click-it
-- Window close button (winbar)

local CloseButton = {
    condition = function(self)
        return not vim.bo.modified
    end,
    -- a small performance improvement:
    -- re register the component callback only on layout/buffer changes.
    update = {'WinNew', 'WinClosed', 'BufEnter'},
    { provider = " " },
    {
        provider = "",
        hl = { fg = "gray" },
        on_click = {
            minwid = function()
                return vim.api.nvim_get_current_win()
            end,
            callback = function(_, minwid)
                vim.api.nvim_win_close(minwid, true)
            end,
            name = "heirline_winbar_close_button"
        },
    },
}

return CloseButton
