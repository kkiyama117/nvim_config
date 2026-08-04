# Issues: treat `*.dpp` (dpp.vim hooks file) as a new file type

Status: DONE through Route 2. A, C, D4, D5, D6, D8, D9 + bridge fixes + custom
`tree-sitter-dpp` grammar (D1b) with injections → emmylua works on `*.dpp`
(verified 2025-08-04). Open decision 3 resolved (wrapper stripped).

Goal: `*.dpp` = dpp.vim `hooks_file` format. Looks almost like a Lua file,
but contains hook blocks read by dpp.vim:

```
-- lua_add {{{
(contents written by lua)
-- }}}
-- rust {{{
(contents written by viml, but always wrapped in `lua << EOF` / `EOF` to treat as lua)
-- }}}
```

Optionally: treat with kakehashi — the Lua inside blocks is handled like
"python inside markdown" (embedded language analysis + bridge to emmylua_ls).

## 0. Verified current state

| Item | Result |
|------|--------|
| `*.dpp` filetype | empty (`ft=` confirmed headless) — no ftdetect, no syntax, no LSP |
| dpp.vim syntax/ftdetect | none shipped (only `dpp-ext-toml` handles `deps/*.toml`) |
| Existing `.dpp` file | `lua/hooks/heirline.nvim.dpp` (used via `hooks_file` in `deps/nvim/ui.toml`) |
| State rebuild | `lua/hooks/**/*.dpp` already in `checkFiles` (`denops/dpp.ts:285`) |
| dpp hooks parser | `parseHooksFile()` in `denops/dpp/utils.ts` — see section B |
| kakehashi | v0.9.0, Rust binary; languageId → `base` fallback → parser; queries per searchPath; `bridge._self` = host-doc bridge |

## A. Filetype detection

| # | Issue | Status |
|---|--------|--------|
| A1 | No `ftdetect` for `*.dpp`. Need `ftdetect/dpp.vim` (`au BufRead,BufNewFile *.dpp setf dpp`) or `filetype.lua`. | DONE: `ftdetect/dpp.vim` (setfiletype, not set ft, so later detection can override). Verified headless: `ft=dpp` with real config and with minimal runtimepath. |
| A2 | Filetype name `dpp` is free (no collisions), but must not shadow future dpp.vim-shipped detection. | DONE: verified — dpp.vim ships no ftdetect/syntax for `dpp`. |

## B. dpp.vim's real parser semantics (tooling must mirror these)

`parseHooksFile()` (`denops/dpp/utils.ts:153`) — verified rules:

| # | Rule |
|---|------|
| B1 | Start marker is the default `{{{` (configurable via `hooksFileMarker`, default `"{{{,}}}"`). `-- lua_add{{` (2 braces) does **not** match — must be `-- lua_add {{{` or `-- lua_add{{{`. Existing files use the spaced form. |
| B2 | Hook name regex: `\s+([0-9a-zA-Z_-]+)\s*` **before** the marker. Only `hook_{add,source,post_source,post_update,pre_update,done_update,depends_update,post_check_update}` and `lua_*` variants become hooks; **anything else becomes a ftplugin key** (`-- dpp {{{` / `-- lua_dpp {{{` = ftplugin for filetype `dpp`). |
| B3 | End marker = line **ending with** `}}}`; the end line itself is excluded from content; lines ending with `{{{` inside a block increment nesting. |
| B4 | `lua_xxx` blocks are converted to `hook_xxx` and executed as `:lua`. |

## C. Client-side editing (syntax / fold / indent)

| # | Issue | Status |
|---|-------|--------|
| C1 | No `syntax/dpp.vim`. Minimal viable: `runtime! syntax/lua.vim` + highlight marker lines (`^-- \w\+ {{{`, `^-- }}}`). The `lua << EOF` wrapper lines inside `-- rust` blocks are Lua parse errors (see D3 — same issue in kakehashi). | DONE: `syntax/dpp.vim` — `runtime! syntax/lua.vim` + groups `dppMarker/dppMarkerStart/dppHookName/dppMarkerOpen/dppMarkerEnd/dppLuaWrapper`. Marker matches defined after lua.vim so they win over luaComment at the same start col; `dppMarkerStart` defined last among contained items (same-position rule, `-` is in the name char class). Verified: L1C2=dppMarkerStart, L1C4=dppHookName, C12=dppMarkerOpen, L5/L7=dppLuaWrapper, L8=dppMarkerEnd. |
| C2 | Folding: hook blocks (`-- name {{{` ... `-- }}}`) must fold; ideally Lua structure *inside* the blocks also folds (python-in-markdown style). | DONE (2026-08-04): `foldmethod=expr` in `after/ftplugin/dpp.lua` — one `foldexpr` (`v:lua.__dpp_fold`) combines (1) a marker base level (dpp's hooksFileMarker semantics incl. nested `{{{`) and (2) `vim.treesitter.foldexpr()` for Lua bodies (lua parser registered for filetype `dpp` via `vim.treesitter.language.register('lua', 'dpp')`; nvim's built-in fold machinery caches + updates incrementally). Nothing folds outside hook blocks. Verified headless: `lua_add` 1-76, `lua_source` 78-149, `function` folds (10-46), `if` (14-17), keymap `function()...end` folds; `zc` on the function line folds just the function; close marker stays inside the block fold. Note: `foldmethod=syntax` was rejected — bundled `syntax/lua.vim` defines `luaError`/`luaParenError` as `syn match` on `end`/`)`, which beat region-`end` (syn-priority: match > region end) and prevent any `fold` region from closing. |
| C3 | Indent: reuse Lua's `indentexpr` via `after/ftplugin/dpp.lua` (mirror the `lua` entry in `lua/hooks/ft.lua`). | DONE: `after/ftplugin/dpp.lua` — sw/sts/ts=2, expandtab, `commentstring=-- %s`, plus C2 folding. Verified: sw=2, cms=`-- %s`. |
| C4 | Alternative to `after/ftplugin`: use dpp's own ftplugin mechanism — a `-- lua_dpp {{{` block in any hooks file (B2). `b:undo_ftplugin` is auto-defined. | NOT TAKEN (alternative; `after/ftplugin` chosen). Revisit if per-plugin ftplugin divergence is needed. |

## D. kakehashi integration — core design fork

kakehashi 0.9.0 mechanics (from source): languageId (= nvim filetype) →
`base` fallback → parser from `searchPaths/<base>/parser/<lang>.so` or
explicit `languages.<lang>.parser` path; queries from
`searchPaths/<base>/queries/<lang>/{highlights,injections}.scm` with
`; inherits:` support; bridge per injection language; `bridge._self` =
host-document bridge.

| # | Issue | Status |
|---|-------|--------|
| D1 | **No `tree-sitter-dpp` grammar exists** in the nvim-treesitter registry → auto-install fails (`~/.local/share/kakehashi/failed_parsers`). Two routes: | RESOLVED — Route 2 implemented and verified (D1b) |
| D1a | **Route 1 (cheap):** `languages.dpp = { base = "lua" }` — whole file parsed with `lua.so`. Works because the file is "almost lua" (markers are `--` comments). No parser to build. | SUPERSEDED by Route 2 (was verified working: 18 tokens) |
| D1b | **Route 2 (true "python-in-markdown"):** write a small custom `tree-sitter-dpp` grammar (comment lines + `hook_block` + `content` node), compile to `dpp.so`, wire via `languages.dpp.parser = "<path>/dpp.so"` (explicit path is the documented escape hatch; a byte-copy of `lua.so` won't work — kakehashi loads the `tree_sitter_dpp` symbol). Then `queries/dpp/injections.scm` can express `(hook_block (content) @injection.content (#set! injection.language "lua"))` with `#offset!` to strip the `-- name {{{` / `-- }}}` lines and the `lua << EOF` / `EOF` wrapper. | DONE — see "Route 2 implementation" section below. Virtual URIs carry the injection language's extension (`kakehashi-virtual-uri-{id}.lua`, `src/lsp/bridge/protocol/virtual_uri.rs`) → injected lua blocks DO reach emmylua (verified). |
| D2 | **Injection is impossible without a grammar:** with the lua parser as host there is no AST node spanning the region between `-- lua_add {{{` and `-- }}}` (two separate comment nodes). So Route 1 = whole-document-as-lua, **no per-block isolation** (cross-block symbols visible — actually an advantage for Lua). | CONFIRMED (source reading) |
| D3 | Route 1 diagnostic noise: `lua << EOF` is a Lua **syntax error** (`lua` call + `<<`), `EOF` alone is valid (bare call). Bridged to emmylua_ls → one spurious diagnostic per wrapped block. Route 2 avoids this (wrapper stripped by `#offset!`). | CONFIRMED empirically: dpp content renamed `.lua` produces `expected '=' for assignment` on the `lua << EOF` line (5 diags total incl. `undefined global variable: vim`). |
| D4 | Queries location: current `searchPaths` = `~/.local/share/kakehashi` + kakehashi.nvim plugin dir only — nvim config dir is **not** a searchPath. Options: put `queries/dpp/*.scm` under `~/.local/share/kakehashi/queries/dpp/` (out of repo), or add `$NVIM_CONFIG_HOME` (or a `kakehashi/` subdir) to `init_options.searchPaths` in `lua/hooks/kakehashi.nvim.lua`. | DONE: repo-owned `$NVIM_CONFIG_HOME/kakehashi` added to searchPaths in `lua/hooks/kakehashi.nvim.lua`; `kakehashi/queries/dpp/highlights.scm` created. Verified: 18 real semantic tokens for test.dpp (after lua parser un-crashed, see E6). |
| D5 | Highlights for `dpp`: `queries/dpp/highlights.scm` with `; inherits: lua` (Route 1: whole file; Route 2: host-level nodes only, no-ops for lua node types). | DONE: `; inherits: lua` works (tokens verified). |
| D6 | **Bridge config must be added explicitly** — the `_` wildcard has only `autoInstall`; markdown's `bridge.lua → emmylua_ls` aggregation is markdown-specific. Add `languages.dpp.bridge.lua = { aggregation = { ['_'] = { priorities = { 'emmylua_ls' } } } }` (Route 2, per-block) and/or rely on `bridge._self` (Route 1, host doc). | DONE (config): `languages.dpp = { base='lua', bridge={ _self={enabled=true} } }` + `emmylua_ls.languages` includes `dpp` (via `server_filetypes.emmylua_ls`). PLUS: `_` wildcard now seals `textDocument/publishDiagnostics` (`layers.aggregation priorities = {}`) → pull-only diagnostics, verified single set (5, not 10). Route 2 will additionally need `languages.dpp.bridge.lua = { aggregation = { ['_'] = { priorities = {'emmylua_ls'} } } }` (mirror markdown). |
| D7 | Route 1 base-inheritance side effect: `dpp.base='lua'` inherits `lua.bridge._self.enabled = true` (from `host_bridge_languages`) → host document bridged. Server selection for derived host language `dpp` (`languageServers` has emmylua under `languages = ['lua']`) is **unverified** — needs an empirical check. | VERIFIED — host bridging is configured and emmylua spawns/handshakes/answers the pull, **but emmylua keys documents by URI extension: `.dpp` URIs are ignored regardless of languageId** (control: same content as `.lua` → 5 diags; as `.dpp` with languageId `lua` → 0). kakehashi forwards the host doc verbatim (real URI). Conclusion: Route 1 host bridge CANNOT serve emmylua for `*.dpp`; only injected virtual docs (`kakehashi-virtual-uri-*.lua`) reach it → **Route 2 is required** for emmylua. Host bridge config kept (harmless; works if emmylua ever accepts `.dpp`). |
| D8 | `autoInstall`: Route 1 needs none (base resolves). Route 2 with explicit `parser` skips install. Plain `dpp = {}` would attempt registry lookup and fail. Consider `languages.dpp.autoInstall = false` to be explicit. | DONE: base=lua resolves; no failed_parsers entry for dpp; no autoInstall change needed. |
| D9 | Add `'dpp'` to `config.filetypes()` in `lua/vimrc/kakehashi_config.lua` so kakehashi attaches. Do **not** add `dpp` to `host_bridge_languages` (not a real host language in Route 1). | DONE: kakehashi attaches to dpp buffers (verified `clients=kakehashi`). Via `server_filetypes.emmylua_ls` extension — do NOT add to `host_bridge_languages`. |

## E. Interactions with existing machinery

| # | Issue | Status |
|---|-------|--------|
| E1 | `LspTokenUpdate` handler sets `syntax=OFF` + `vim.treesitter.stop()` for kakehashi-attached buffers → client-side syntax (C1) only matters pre-tokens / as fallback. | Confirmed for dpp: syntax=OFF after tokens arrive. |
| E2 | tree-sitter-manager's FileType fallback list: do **not** add `dpp` unless a client-side parser alias is registered (`vim.treesitter.language.add('dpp', ...)` pointing at `lua.so`), else `vim.treesitter.start` fails. | NOT APPLIED (dpp not added to the list). |
| E3 | `ft.lua`-style per-filetype settings: the `-- dpp {{{` / `-- lua_dpp {{{` ftplugin blocks in hooks files (B2) become live **only after** the filetype exists — natural home for dpp-specific options (sw=2, commentstring `-- %s`, foldmethod=marker). | Available now (filetype exists). `after/ftplugin/dpp.lua` covers the defaults (C3). |
| E4 | `kakehashi_bridge.inherit` needs no change — emmylua_ls is already pushed with `languages: ['lua']`, which matches the injection language. | SUPERSEDED — bridge needed substantial fixes (see E7). |
| E5 | Migration option: existing `hooks_file = ".../*.lua"` entries in `deps/*.toml` can stay (they are already parsed by the same `parseHooksFile` — `.lua` extension is incidental). `.dpp` is only about editor treatment, not dpp behavior. | Noted. |
| E6 | kakehashi `failed_parsers` contained `lua` (crash-marked 2026-07-31) → kakehashi SKIPPED all lua parsing (no semantic tokens for lua/dpp). | FIXED: removed `lua` from `~/.local/share/kakehashi/failed_parsers` (backup `/tmp/failed_parsers.bak`); kakehashi re-marks if it truly crashes. Verified 18 real tokens for test.dpp. |
| E7 | **Pre-existing bridge bugs fixed during this work** (`lua/vimrc/kakehashi_bridge.lua`): (1) `get_vim_lsp_config` fallback `vim.lsp.configs` is nil on nvim 0.13 → NO bridged server was ever pushed (emmylua/pyright/etc. all dead since the 0.13 upgrade); fixed via `vim.lsp.config[name]` (resolved metatable table, merges nvim-lspconfig's runtime `lsp/<name>.lua`). (2) `server_filetypes` is now an extension merged with the nvim config's filetypes (not a pure fallback) — required for `dpp` to reach emmylua's languages list. (3) Diagnostic pull race: the initial `textDocument/diagnostic` pull fires before `didChangeConfiguration` lands → kakehashi answers "no host-capable server" and nvim never re-pulls; fixed with `refresh_diagnostics_after_config` (poll `effectiveConfiguration` until servers are visible, settle 1.5 s, re-pull only buffers with 0 diagnostics). (4) `_` wildcard now seals `textDocument/publishDiagnostics` (pull-only) so push+pull don't double-deliver (verified 5, not 10).

## Route 2 implementation (verified 2025-08-04)

- Grammar: `kakehashi/tree-sitter-dpp/` (grammar.js + tree-sitter.json +
  build.sh + README). Key lexing trick: marker/wrapper rules are single
  regex tokens INCLUDING the trailing newline → strictly longer than the
  content token `[^
]*` → tree-sitter's longest-match lexer recognizes
  them unambiguously (a whole-line content token would swallow `-- }}}`;
  `prec()` does NOT break lexical length ties). Consequence: marker lines
  have no sub-nodes. Built with tree-sitter-cli 0.26.9 (ABI 15, matches
  kakehashi's tree-sitter 0.26.11), `cc -shared -fPIC -O2 -I src`;
  installed at `kakehashi/parser/dpp.so` (exports `tree_sitter_dpp`).
- `kakehashi/queries/dpp/injections.scm`: per-line captures + combined:
  `(hook_block (hook_line (line) @injection.content)) (#set! injection.language
  "lua") (#set! injection.combined)` — kakehashi merges ALL captures of the
  pattern DOCUMENT-WIDE into ONE virtual doc (`build_combined_injection`,
  `src/language/injection/discovery.rs`), gaps (wrapper/marker lines) become
  empty lines. Wrapper lines (`lua << EOF`/`EOF` = distinct node types) are
  excluded from the capture → never in the virtual doc → no spurious
  `expected '=' for assignment`. Open decision 3 RESOLVED: wrapper stripped.
- `kakehashi/queries/dpp/highlights.scm`: host-level captures only
  (`(start_marker_line) @comment` etc.); `; inherits: lua` dropped — injected
  regions are tokenized by lua's own highlights.
- Config (`lua/vimrc/kakehashi_config.lua`): `languages.dpp = { parser =
  $NVIM_CONFIG_HOME/kakehashi/parser/dpp.so (absolute), autoInstall = false,
  bridge.lua.aggregation._.priorities = { 'emmylua_ls' } }`; `base` and
  `_self` removed (host bridge would not reach emmylua anyway — D7).

Verified end-to-end (deno LSP harness + headless nvim):
- `Language dpp loaded.` / `Detected 'dpp' via languageId` /
  `Eager open: spawning emmylua_ls with 1 injections` (one combined doc).
- semantic tokens arrive (host marker @comment + injected lua); nvim sets
  syntax=OFF via LspTokenUpdate (155 tokens on the fixture).
- 4 emmylua diagnostics, HOST positions correct: L2C1 `undefined global
  variable: vim` (lua_add), L4C7 `t is never used` (lua_add), L11C1 `vim`
  (rust, after wrapper), L15C1 `vim` (dpp). No wrapper-line errors.
- Timing: emmylua's FIRST analysis is slow (~40-65 s cold); later
  diagnostics arrive via kakehashi's workspace/diagnostic/refresh push.
- `failed_parsers` has no dpp entry (parser never crashed).

## Open decisions (before implementation)

1. **Route 1 vs Route 2** — RESOLVED: Route 2 implemented (above).
2. Queries location — DONE: repo-owned `$NVIM_CONFIG_HOME/kakehashi`.
3. `-- rust {{{` blocks inject `lua` always (user convention: content is
   wrapped in `lua << EOF`); wrapper lines STRIPPED from the virtual doc
   (excluded node types — no `#offset!` needed). — RESOLVED.
   Remaining optional polish (not taken): per-name injection language
   (e.g. `vim` blocks when raw vimscript appears); `-- dpp {{{` ftplugin
   blocks for per-plugin options (C4); client-side
   `vim.treesitter.language.add('dpp', lua.so)` fallback (E2).

## Suggested sequence

A1 → C1/C2/C3 (filetype + ftplugin + syntax) → D9/D6 + D4 (kakehashi
Route 1 MVP) → verify D7 → decide Route 2 only if block
isolation/diagnostics justify it.

DONE through Route 2 (custom `tree-sitter-dpp` grammar + injections +
`bridge.lua` aggregation) — emmylua works on `*.dpp` (verified).
Remaining optional polish: per-name injection languages, C4 ftplugin
blocks, E2 client-side parser alias — see "Open decisions".

### Recovery notes for a fresh session

### Changed / created files (this work)

| File | What |
|------|------|
| `ftdetect/dpp.vim` | created — `*.dpp` → filetype dpp |
| `syntax/dpp.vim` | created — lua base + marker groups |
| `after/ftplugin/dpp.lua` | created — indent, commentstring, folding |
| `kakehashi/queries/dpp/highlights.scm` | created — `; inherits: lua` → Route 2: host captures only (`@comment` markers) |
| `kakehashi/queries/dpp/injections.scm` | created — per-line combined lua injection, wrapper excluded |
| `kakehashi/tree-sitter-dpp/` | created — grammar.js, tree-sitter.json, build.sh, README, generated src/, dpp.so |
| `kakehashi/parser/dpp.so` | created — built grammar (tree_sitter_dpp symbol), loaded via `languages.dpp.parser` |
| `lua/hooks/kakehashi.nvim.lua` | searchPaths += `$NVIM_CONFIG_HOME/kakehashi` |
| `lua/vimrc/kakehashi_config.lua` | `languages.dpp` (parser + bridge.lua aggregation), `server_filetypes.emmylua_ls` + `dpp`, pull-only seal on `_` |
| `lua/vimrc/kakehashi_bridge.lua` | 0.13 config lookup, server_filetypes extension, diag re-pull |
| `~/.local/share/kakehashi/failed_parsers` | removed `lua` (backup `/tmp/failed_parsers.bak`) |
| dpp state (`~/.cache/nvim/dpp/nvim/state.vim` + `startup.vim`) | rebuilt to embed the new hook |

NOTE: `git status` also shows PRE-EXISTING uncommitted changes NOT from
this work: `denops/dpp.ts`, `deps/nvim/ui.toml`,
`lua/bootloader/autocmds.lua`, rename `lua/hooks/heirline.nvim.lua` →
`lua/hooks/heirline.nvim.dpp`. Leave them alone.

### CRITICAL gotcha: dpp state embeds hooks

`lua/hooks/*.lua` hook files are read at `dpp#make_state()` time and their
content is EMBEDDED into `~/.cache/nvim/dpp/nvim/state.vim`. Editing a
hook file does NOT take effect until the state is rebuilt. In the user's
GUI workflow this happens automatically: BufWritePost on config files →
`bootloader/dpp/make_state.run` → `Dpp:makeStatePost` → `:restart`
(`lua/bootloader/autocmds.lua`, `lua/bootloader/dpp/auto_update.lua`).
Files required at runtime (e.g. `vimrc/kakehashi_bridge.lua`) take
effect immediately — only the hook file content itself is embedded.

Headless rebuild recipe (used and verified):
```
nvim --headless -c "lua pcall(vim.api.nvim_del_augroup_by_name, 'vimrc')" \
  -c "lua vim.defer_fn(function() vim.fn['dpp#make_state'](vim.g['vimrc#dpp#cache_home'], vim.g['vimrc#dpp#denops_script']) end, 20000)" \
  -c "lua <poll state.vim mtime, qa! when updated>"
```
(`vimrc` augroup deletion suppresses the auto-`:restart`.) State dir:
`~/.cache/nvim/dpp/nvim/` — note: NOT `.dpp/` (that is the plugin link dir).

### Verification recipes (headless, real config)

Test fixtures: `/tmp/dpptest/test.dpp` (hook blocks incl. `lua << EOF`
wrapper), `/tmp/dpptest/control.lua` (2 syntax errors), root marker
`.luarc.json` in `/tmp/dpptest` (emmylua workspace root).

- Attach + tokens: open dpp file, wait 20-25 s, check
  `vim.lsp.get_clients({bufnr=0})` contains kakehashi, `vim.bo.syntax ==
  'OFF'`, and request `textDocument/semanticTokens/full` (expect 18).
- Diagnostics: open control.lua, wait ~25 s, `vim.diagnostic.get(0)` →
  5 items, single set. The initial pull races the bridge's
  `didChangeConfiguration`; `refresh_diagnostics_after_config` in
  `lua/vimrc/kakehashi_bridge.lua` re-pulls after the config lands
  (poll `kakehashi/internal/effectiveConfiguration`, settle 1.5 s,
  only buffers with 0 diagnostics).
- kakehashi debug stderr: nvim relays it into
  `~/.local/state/nvim/logs/lsp.log` as
  `[ERROR] .../_transport.lua ... "transport" "kakehashi" "stderr"`
  lines (sometimes missing — unreliable; use the deno harness below).
- Scripted LSP session harness (isolates kakehashi, full stderr with
  `RUST_LOG=kakehashi=debug`): deno script speaking stdio LSP to
  `kakehashi` (no subcommand = LSP mode; NO `--stdio` flag). A working
  copy lived at `/tmp/kh_lsp_test.ts` (may not survive reboot):
  initialize with `initializationOptions` (searchPaths + languages),
  didChangeConfiguration with `settings.kakehashi.languageServers`,
  didOpen with `languageId`, then pull `textDocument/diagnostic`.
  Key log lines seen: `[emmylua_ls] LSP handshake completed
  successfully`, `Collected N pull-layer diagnostics`, `Detected 'dpp'
  via languageId`.
- `kakehashi diagnose --config-file <toml> <file>`: CLI-mode bridge
  test (pull-only) — worked and returned 5 emmylua diags.

### Environment facts

- nvim 0.13.0-dev (`vim.lsp.configs` REMOVED; use `vim.lsp.config[name]`
  resolved table; `vim.lsp.get_buffers_by_client_id` deprecated →
  `client.attached_buffers`).
- kakehashi 0.9.0 binary; source clone was at `/tmp/kakehashi`
  (re-clone https://github.com/atusy/kakehashi if needed). Key sources:
  `src/language/coordinator.rs` (detection/base), `src/language/loader.rs`
  + `query_loader.rs` (parser `parser/<lang>.so` and
  `queries/<lang>/<kind>.scm` resolution, `; inherits:` directive),
  `src/lsp/bridge/protocol/virtual_uri.rs` (virtual docs get the
  injection language's extension — why injection reaches emmylua),
  `src/lsp/bridge/coordinator.rs` + `config/settings.rs` (`_self` host
  bridge, `RootMarker`, `layers.aggregation` wire seal).
- deno 2.9.4 (mise).

### Route 2 blueprint (remaining work)

1. Grammar: small `tree-sitter-dpp` (grammar.js): document = lines;
   `hook_block` = `start_marker_line (-- name {{{)` + content lines +
   `end_marker_line (-- }}})`; mirror B1-B3 (names `[0-9a-zA-Z_-]+`,
   end marker = line ending `}}}`, nested `{{{` counting).
2. Compile to `dpp.so` (tree-sitter-cli; kakehashi loads symbol
   `tree_sitter_dpp` — a renamed lua.so copy does NOT work). Put it in
   the repo-owned searchPath dir (`$NVIM_CONFIG_HOME/kakehashi/parser/`)
   and set `languages.dpp.parser` to that path (explicit path is the
   escape hatch; relative paths resolve against the config source).
   `base` stays `lua`-free once the own parser is set (derived-with-own-
   parser path). Set `languages.dpp.autoInstall = false` to be explicit.
3. `queries/dpp/injections.scm`: `(hook_block (content)
   @injection.content (#set! injection.language "lua"))` + `#offset!` to
   strip the marker lines; decide wrapper handling (open decision 3):
   either keep `lua << EOF`/`EOF` lines in the content (then emmylua
   reports one error per wrapper — D3) or strip them per block with
   `#offset!` (offset is relative to the content node, so this only
   works if the grammar models the wrapper, e.g. a `wrapped_content`
   node or per-line structure).
4. `queries/dpp/highlights.scm`: keep `; inherits: lua` + add marker
   groups (`(start_marker) @comment` etc.) for kakehashi tokens.
5. `languages.dpp.bridge.lua = { aggregation = { ['_'] = {
   priorities = { 'emmylua_ls' } } } }` in `kakehashi_config.languages()`
   (mirror markdown). Host bridge (`_self`) can stay or go.
6. Verify: tokens (marker groups), hover/completion inside lua blocks,
   diagnostics per block; expect virtual URIs
   `kakehashi-virtual-uri-*.lua` (grep kakehashi debug stderr).
7. Consider `-- dpp {{{` / `lua_dpp` ftplugin blocks (C4) and whether
   `vim.treesitter.language.add('dpp', lua.so)` for the client-side
   fallback (E2) is worth it.
