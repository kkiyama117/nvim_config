; dpp -> lua injection (Route 2).
;
; Every hook block's content is Lua: `lua_*` hooks are run as `:lua` by
; dpp.vim, and other blocks (`-- rust {{{` etc.) are Vimscript ftplugin
; keys whose content is wrapped in `lua << EOF` / `EOF` heredocs — still
; Lua. Per-line captures + `injection.combined` merge all content lines of
; one block into a single virtual document; the wrapper lines (distinct
; node types, not captured) become blank lines in that document, so
; emmylua never sees `lua << EOF` (which is not valid Lua).
;
; Each capture maps back to its host line, so hover/completion/diagnostics
; positions are correct per block.

(hook_block
  (hook_line
    (line) @injection.content)
  (#set! injection.language "lua")
  (#set! injection.combined))
