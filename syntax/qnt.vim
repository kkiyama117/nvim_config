" Vim syntax file
" Language: Quint
" Maintainer: Igor Konnov, Informal Systems, igor at informal.systems
" Latest Revision: 03 February 2023
"
" Vendored from informalsystems/quint (vim/quint.vim) with fixes:
"   * b:current_syntax is `qnt` (matches the filetype), not `quint`;
"   * quintOper is a syn match (syn keyword silently rejects non-keyword
"     chars, leaving the group empty);
"   * quintDelim is three separate matches (extra args were ignored);
"   * quintString skips escaped quotes;
"   * dropped the link to the never-defined quintBlockError group.
"
" Ordering note: when several items match at the same position, Vim gives
" priority to the item defined LAST (:help syn-priority). Operators are
" therefore defined first (so comments/numbers/strings below win over
" them), and single-char before multi-char (so `<=` etc. win over `<`/`>`).

if exists("b:current_syntax")
  finish
endif

let b:current_syntax = "qnt"

" clear the old stuff
syn clear

" operators (defined first — see the ordering note in the header)
syn match quintOper "[+\-*/%^<>]"
syn match quintOper "==\|!=\|<=\|>=\|=>\|->\|<-"
syn match quintOper "\."

" comments
syn match quintComment "//.*$"
syn region quintComment start="/\*" end="\*/" fold

" identifiers
syn match quintIdent "[a-zA-Z_][a-zA-Z0-9_]*"

" numbers and strings
syn match quintNumber '-\?\(0x[0-9a-fA-F]\([0-9a-fA-F]\|_[0-9a-fA-F]\)*\|0\|[1-9]\([0-9]\|_[0-9]\)*\)'
syn region quintString start='"' end='"' skip='\\"'

" types
syn keyword quintType int str bool Set List Rec Tup

" typedefs
syn keyword quintTypedef type

" built-in values
syn keyword quintValue Bool Int Nat
syn keyword quintBoolValue false true

" conditionals
syn keyword quintCond if else

" declarations
syn keyword quintDecl module import from export const var val def pure nondet action temporal assume run

" standard operators
syn keyword quintStd Set List Map Rec Tup
syn keyword quintStd not and or iff implies all any as leadsTo

" curly braces
syn region quintBlock start="{" end="}" fold transparent contains=ALLBUT,quintCurlyError
syn match quintCurlyError     "}"

" parentheses
syn region quintParen start="(" end=")" fold transparent contains=ALLBUT,quintParenError
syn match quintParenError     ")"

" braces
syn region quintBrace start="\[" end="\]" fold transparent contains=ALLBUT,quintBraceError
syn match quintBraceError     "\]"

" delimiters
syn match quintDelim ","
syn match quintDelim ":"
syn match quintDelim ";"


" highlighting instructions
hi def link quintComment     Comment
hi def link quintIdent       Identifier
hi def link quintType        Type
hi def link quintTypedef     Typedef
hi def link quintString      String
hi def link quintNumber      Number
hi def link quintBoolValue   Boolean
hi def link quintValue       Constant
hi def link quintDecl        StorageClass
hi def link quintStd         Statement
hi def link quintOper        Operator
hi def link quintCond        Conditional
hi def link quintParenError  Error
hi def link quintBraceError  Error
