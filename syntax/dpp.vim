" Vim syntax file for dpp.vim hooks files (*.dpp).
"
" The hooks file is almost a Lua file: hook blocks are delimited by comment
" marker lines, e.g.
"   -- lua_add {{{
"   (lua code)
"   -- }}}
" Base highlighting is Lua; the marker lines and the `lua << EOF` / `EOF`
" wrapper lines get dedicated groups.
" See .agents/issues/dpp-filetype.md.
"
" NOTE: the marker matches are defined AFTER runtime! syntax/lua.vim so that
" they win over luaComment at the same start column (syn-priority: last
" defined wins at the same position).

if exists('b:current_syntax')
  finish
endif

runtime! syntax/lua.vim
unlet b:current_syntax

" Hook start marker line: `-- name {{{` (name chars per dpp.vim
" parseHooksFile(): [0-9a-zA-Z_-]+)
syntax match dppMarker '^--.*{{{.*$' contains=dppMarkerStart,dppHookName,dppMarkerOpen
" NOTE: dppMarkerStart is defined LAST: at the same start column (the `--`
" prefix) it would otherwise lose to dppHookName (whose char class includes
" `-`), per syn-priority (last defined wins at the same position).
syntax match dppHookName '[0-9A-Za-z_-]\+' contained
syntax match dppMarkerOpen '{{{' contained
syntax match dppMarkerStart '^--\s*' contained

" Hook end marker line: `-- }}}` (dpp: line ends with `}}}`)
syntax match dppMarkerEnd '^--.*}}}$'

" `lua << EOF` / `EOF` wrappers inside viml-style blocks (not real Lua)
syntax match dppLuaWrapper '^lua << EOF$'
syntax match dppLuaWrapper '^EOF$'

hi def link dppMarkerStart Comment
hi def link dppHookName Function
hi def link dppMarkerOpen Delimiter
hi def link dppMarker Comment
hi def link dppMarkerEnd Comment
hi def link dppLuaWrapper Comment

let b:current_syntax = 'dpp'
