" Filetype detection for dpp.vim hooks files (*.dpp).
"
" Format: hook blocks delimited by comment markers, e.g.
"   -- lua_add {{{
"   (lua code)
"   -- }}}
" See .agents/issues/dpp-filetype.md for the full issue list.
autocmd BufRead,BufNewFile *.dpp setfiletype dpp
