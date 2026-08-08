# PLAN: Bridge lua heredoc bodies in viml-format dpp blocks to emmylua

Status: planned (not implemented)
Owner: AI agents
Related: `after/ftplugin/dpp.lua`, `~/.config/kakehashi/tree-sitter-dpp/` (chezmoi),
`lua/vimrc/kakehashi_config.lua`, `after/lsp/kakehashi.lua`

## 1. Goal

Make the lua code inside viml-format dpp hook blocks (`" hook_* {{{` with
`lua << EOF ... EOF` heredocs, e.g. `lua/hooks/shared/ddu_gin.dpp`) reach
emmylua_ls through the kakehashi bridge, so viml-format dpp files get the
same LSP features (completion/hover/diagnostics) as lua-format ones.

## 2. Background (current state, all verified)

- Grammar (`tree-sitter-dpp/grammar.js`) has two start-marker node types:
  `lua_start_marker_line` (`lua_*` names) and `viml_start_marker_line`
  (`hook_*` / target-filetype names); both accept `--` and `"` prefixes.
- `queries/dpp/injections.scm`:
  - `lua_*` blocks → whole block injected as **lua** → bridged to emmylua
    via `languages.dpp.bridge.lua` (verified: `kakehashi diagnose` spawns
    emmylua_ls and opens the virtual document).
  - `hook_*` / filetype blocks → whole block injected as **vim**. The vim
    grammar parses the `lua << EOF` heredoc natively and injects the body
    as lua (nested layer, kakehashi's own features only).
- **Why the nested lua does not bridge**: kakehashi opens virtual documents
  only on servers that handle the injection language of the host document's
  direct injections. The dpp host's direct injections are `vim`; no bridged
  server handles vim, so the vim documents are never opened and their
  nested lua never reaches emmylua. `languages.vim.bridge.lua` was tried
  and is dead config (removed) — the vim layer itself is never opened.
- nvim side (`after/ftplugin/dpp.lua`) already handles both formats
  (vim/lua parser selection, folding, commentstring) — no changes needed
  for this plan.

## 3. Design

Add a grammar-level `heredoc` / `heredoc_body` grouping so queries can
capture the lua body directly from the dpp tree, and inject it as lua
(host = dpp → `languages.dpp.bridge.lua` applies → emmylua).

### 3.1 Grammar changes (`~/.local/share/chezmoi/dot_config/kakehashi/tree-sitter-dpp/grammar.js`)

```js
// lua << EOF ... EOF  (here-doc; body = the lua content lines)
heredoc: ($) => seq(
  $.wrapper_start_line,
  $.heredoc_body,
  $.wrapper_end_line,
),

// the lua content lines between the wrapper lines
heredoc_body: ($) => repeat1($.line),

// a line inside a hook block: heredoc or content line
hook_line: ($) => choice($.heredoc, $.line),
```

`wrapper_start_line` / `wrapper_end_line` rules stay as-is (single regex
tokens including the trailing newline).

### 3.2 Query changes (`queries/dpp/injections.scm`)

Keep the existing vim injection for the whole viml block, ADD a lua
injection for the heredoc bodies:

```scm
; lua heredoc bodies inside viml blocks -> lua (bridged to emmylua)
(
  (hook_block
    (viml_start_marker_line)
    (hook_line
      (heredoc
        (heredoc_body) @injection.content)))
  (#set! injection.language "lua")
  (#set! injection.include-children)
)
```

Notes:
- Each `heredoc_body` is ONE contiguous region → its own virtual document
  (no `injection.combined`). Multiple bodies in one block = multiple
  contiguous lua documents; the old "kakehashi refused to bridge
  completion" problem was specific to the merged NON-contiguous combined
  document, so this should be safe — verify anyway (see §4).
- The vim layer's own nested lua injection (vim's injections.scm) will
  duplicate the body as a second, unbridged lua layer. Harmless (no
  bridge, tokens disabled for dpp) — accept.
- Blocks without heredocs (pure viml) get only the vim injection.

### 3.3 Config changes

None. `languages.dpp.bridge.lua` already bridges dpp-injected lua to
emmylua. Do NOT re-add `languages.vim.bridge.lua` (dead).

## 4. Verification

1. Rebuild: `sh build.sh` in the chezmoi tree-sitter-dpp dir; install
   `dpp.so` → `~/.config/kakehashi/parser/dpp.so`; sync grammar.js/README
   to `~/.config/kakehashi/tree-sitter-dpp/`.
2. `tree-sitter parse` on `lua/hooks/shared/ddu_gin.dpp`,
   `lua/hooks/shared/ddc_skkeleton.dpp`, `lua/hooks/ft.dpp`:
   - 0 ERROR nodes;
   - `heredoc_body` nodes present with exactly the lua lines (no
     `lua << EOF` / `EOF` lines inside).
3. `tree-sitter query` with injections.scm: viml blocks match the vim
   pattern; heredoc bodies match the lua pattern with correct ranges.
4. `kakehashi diagnose` (test config with searchPaths incl.
   `~/.config/kakehashi` + `~/.local/share/kakehashi`, emmylua_ls with
   `languages = ["lua"]` + absolute cmd, `languages.dpp.bridge.lua`):
   - viml file with a deliberate lua error → "Eager open: spawning
     emmylua_ls with N injections" and the error surfaces (or at least
     the virtual document opens — CLI cold-start timing may hide the
     diagnostic itself; the spawn log is the pass/fail signal).
5. nvim headless with the real config: open a viml dpp file → vim parser,
   folding, commentstring unchanged (regression check).

## 5. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| Lexer tie-break flips at the `EOF` line: `line` and `wrapper_end_line` both match `EOF\n` (4 chars); the generated DFA's last-ACCEPTED-wins order may change with the new `heredoc` rule, so `EOF` becomes a `line` and the heredoc never terminates (parse errors) | Empirical check in §4.2. If flipped: add `prec` to `wrapper_end_line` (or restructure the body token) and re-test |
| GLR ambiguity: `repeat1($.line)` + `wrapper_end_line` — at the `EOF` line the parser can continue (`line`) or stop (`wrapper_end_line`); the `line` path dead-ends, GLR should resolve, but verify no exponential blowup on real files | §4.2; keep heredocs short (they are) |
| Multiple lua regions per block break edit-carrying methods (the old combined-document problem) | Per-body regions are contiguous and NOT combined; verify completion bridging via diagnose/real nvim |
| Duplicate lua layers (direct + nested via vim) | Harmless; accept |

## 6. Out of scope / follow-ups

- viml-format filetype blocks (`" go {{{`) with heredocs: same mechanism
  applies automatically (they are `viml_start_marker_line` too).
- kakehashi semantic tokens for dpp buffers stay disabled
  (`after/lsp/kakehashi.lua` on_attach) — treesitter owns highlighting.
- If the grammar tie-break proves unfixable, fallback: keep vim injection
  only (current state) and document that viml files get no LSP features.
