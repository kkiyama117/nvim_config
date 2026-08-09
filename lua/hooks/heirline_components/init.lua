local M = {}

-- COLORS
M.get_colors = require('hooks/heirline_components/colors').setup

M.ViMode = require('hooks/heirline_components/vi_mode')
M.FileName = require('hooks/heirline_components/file_name')
M.Ruler = require('hooks/heirline_components/ruler')
M.ScrollBar = require('hooks/heirline_components/scroll_bar')
M.Git = require('hooks/heirline_components/git')
M.Gin = require('hooks/heirline_components/gin')
M.WorkDir = require('hooks/heirline_components/work_dir')
M.TerminalName = require('hooks/heirline_components/terminal_name')
M.HelpFileName = require('hooks/heirline_components/help_file_name')
M.Spell = require('hooks/heirline_components/spell')
M.SearchCount = require('hooks/heirline_components/search_count')
M.MacroRec = require('hooks/heirline_components/macro_rec')
M.ShowCmd = require('hooks/heirline_components/show_cmd')
M.FileType = require('hooks/heirline_components/file_type')
M.FileSize = require('hooks/heirline_components/file_size')
M.FileLastModified = require('hooks/heirline_components/file_last_modified')
M.FileEncoding = require('hooks/heirline_components/file_encoding')
M.FileFormat = require('hooks/heirline_components/file_format')
M.CloseButton = require('hooks/heirline_components/close_button')
M.TabLine = require('hooks/heirline_components/tabline')
M.LSP = require('hooks/heirline_components/lsp')
M.Overseer = require('hooks/heirline_components/overseer')

return M
