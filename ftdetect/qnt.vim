" Filetype detection for Quint specification files (*.qnt).
" Filetype is `qnt` (matches kakehashi's extension-based language detection),
" not `quint`.
autocmd BufRead,BufNewFile *.qnt setfiletype qnt
