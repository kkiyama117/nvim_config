local M = {}
local conditions = require("heirline.conditions")

-- Configure diagnostic signs (run once, outside the component table)
vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '󰋇',
      [vim.diagnostic.severity.HINT] = '󰌵',
    },
  },
})

local LSPActive = {
    condition = conditions.lsp_attached,
    update = {'LspAttach', 'LspDetach'},
    -- provider = " [LSP]",
    provider = function()
        local names = {}
        for i, server in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
            table.insert(names, server.name)
        end
        return " [" .. table.concat(names, " ") .. "]"
    end,
    hl = { fg = "green", bold = true },
    on_click = {
        callback = function()
            vim.defer_fn(function()
                vim.cmd("LspInfo")
            end, 100)
        end,
        name = "heirline_LSP",
    },
}

local Diagnostics = {
    condition = conditions.has_diagnostics,

    on_click = {
        callback = function()
            vim.diagnostic.setqflist()
        end,
        name = "heirline_diagnostics",
    },

    -- Fetching custom diagnostic icons
    -- NOTE: heirline only copies fields listed in `static` into the component;
    -- fields defined directly in the table are dropped (see cookbook.md `static`).
    static = {
        error_icon = vim.diagnostic.config()['signs']['text'][vim.diagnostic.severity.ERROR],
        warn_icon = vim.diagnostic.config()['signs']['text'][vim.diagnostic.severity.WARN],
        info_icon = vim.diagnostic.config()['signs']['text'][vim.diagnostic.severity.INFO],
        hint_icon = vim.diagnostic.config()['signs']['text'][vim.diagnostic.severity.HINT],
    },

    init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    update = { "DiagnosticChanged", "BufEnter" },

    {
        provider = "![",
    },
    {
        provider = function(self)
            -- 0 is just another output, we can decide to print it or not!
            return self.errors > 0 and (self.error_icon .. self.errors .. " ")
        end,
        hl = { fg = "diag_error" },
    },
    {
        provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
        end,
        hl = { fg = "diag_warn" },
    },
    {
        provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. " ")
        end,
        hl = { fg = "diag_info" },
    },
    {
        provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = "diag_hint" },
    },
    {
        provider = "]",
    },
}

-- I personally use it only to display progress messages!
-- See lsp-status/README.md for configuration options.
-- Note: check "j-hui/fidget.nvim" for a nice statusline-free alternative.
--local LSPMessages = {
--    provider = require("lsp-status").status,
--    hl = { fg = "gray" },
--}

-- TODO: Add navic and set nerd
M.LSPActive = LSPActive
M.LSPDiagnostics = Diagnostics

return M

