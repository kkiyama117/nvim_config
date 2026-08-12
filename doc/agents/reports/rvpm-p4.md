# P4 report — .dpp hooks → rvpm per-plugin hooks

STATUS: PASS

## Counts

| Category | n |
|----------|---|
| dpp fold sections (lua_add/lua_source/hook_*) | 58 |
| deps inline sections (ftplugin/hook_source/lua_add) | 5 |
| ft.dpp filetype blocks → global before.lua | 1 file (12 ft patterns) |
| **Total accounted** | **64** |
| dropped | 0 |
| denops after.lua added (P1, not in dpp) | 2 (ddu, ddc) |

Converter: `scripts/dpp-hooks2rvpm.py` (re-run: `python3 scripts/dpp-hooks2rvpm.py > /tmp/p4-report.json`).

## Files created

```
rvpm/before.lua                          ← lua/hooks/ft.dpp (global FileType rules)
rvpm/plugins/github.com/<owner>/<repo>/
  init.lua / before.lua / after.lua        ← 37 plugins with hooks
lua/hooks/shared/ddc_skkeleton.lua         ← shared multiple_hooks
lua/hooks/shared/ddu_gin.lua               ← shared multiple_hooks (empty body; gin-log in after/ftplugin/)
```

66 hook Lua files under `rvpm/plugins/` + 2 shared modules + updated `rvpm/before.lua`.

Post-process: `stylua rvpm/before.lua rvpm/plugins lua/hooks/shared` (`.stylua.toml` present).

## Shared hooks

| Module | Source | Consumers |
|--------|--------|-----------|
| `lua/hooks/shared/ddc_skkeleton.lua` | `lua/hooks/shared/ddc_skkeleton.dpp` hook_source | `Shougo/ddc.vim/before.lua`, `vim-skk/skkeleton/before.lua` via `require("hooks.shared.ddc_skkeleton").setup()` |
| `lua/hooks/shared/ddu_gin.lua` | `lua/hooks/shared/ddu_gin.dpp` (empty) | `Shougo/ddu.vim/before.lua`, `lambdalisue/vim-gin/before.lua` — no-op; real gin ddu integration lives in `after/ftplugin/gin-log.lua` on config rtp |

## denops readiness idiom

| Hook / file | denops plugin | Why |
|-------------|---------------|-----|
| `Shougo/ddu.vim/after.lua` | ddu | P1: rvpm cannot auto-register `app.ts`; runs `denops#plugin#load` after lazy rtp append |
| `Shougo/ddc.vim/after.lua` | ddc | same |
| ddu.vim init keymaps | ddu | Calls `ddu#start` at **keypress**; ddu loads on `DenopsReady` before user input — no top-level wrapper |
| ddc.vim before.lua | ddc | Calls `ddc#custom#*` at hook time after rtp append; autoload available — same timing as dpp hook_source |
| vim-gin init keymaps | gin | `Gin*` commands at keypress; gin eager on `DenopsReady` — no wrapper |
| skkeleton before.lua | skkeleton | Calls `skkeleton#*` in before.lua; matches dpp (denops_wait dropped; rvpm load_lazy waits) |

No hook required §2.5 `DenopsPluginPost` wrapper beyond the two `after.lua` denops registrations.

## Blocks moved to after.lua

| Hook | Reason |
|------|--------|
| ddu.vim after.lua | denops `app.ts` registration (P1 finding), not post_source |
| ddc.vim after.lua | same |

No dpp `post_source` sections existed; nothing moved for plugin/* timing.

## Translation deviations

| Item | Deviation | Why |
|------|-----------|-----|
| ft.dpp | Wrapped each `-- ft {{{` block in `FileType` autocmd | rvpm global hook has no dpp fold sections |
| deps inline ftplugin | `vim.cmd([[...]])` inside FileType autocmd | mechanical vimscript → lua cmd |
| skkeleton-henkan-highlight highlight | `vim.cmd` per vimscript line | inline hook_source was vimscript |
| ddu_gin shared | Empty module + comment | dpp bodies were empty; gin-log ftplugin unchanged |
| tree-sitter-manager | Used `.dpp` only, skipped duplicate deps inline | same plugin, avoid double setup |

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | 58 sections accounted | PASS — 58 dpp + 5 inline + ft.dpp; 0 dropped |
| 2 | valid Lua | PASS — `luajit -bl` on all generated files |
| 3 | shared hooks | PASS — modules + require from ddc/skkeleton and ddu/vim-gin |
| 4 | rvpm doctor | PASS — 0 errors; depends 19/19; no cycles/duplicates/on_source typos |
| 5 | deterministic | PASS — two converter runs byte-identical (before stylua) |
| 6 | denops idiom | PASS — ddu/ddc after.lua; others justified in table above |

```sh
python3 scripts/dpp-hooks2rvpm.py > /tmp/p4-report.json
stylua rvpm/before.lua rvpm/plugins lua/hooks/shared
export RVPM_NO_AUTOUPDATE=1
RVPM_APPNAME=p4-test sh scripts/rvpm-link.sh
RVPM_APPNAME=p4-test script -qec "rvpm generate" /dev/null
RVPM_APPNAME=p4-test rvpm doctor
```

## Surprises

| Finding | Impact |
|---------|--------|
| `tree-sitter-manager.nvim.dpp` exists but has no deps hooks_file | Converted via url_map override; deps inline skipped to avoid dup |
| `ddu_gin.dpp` hook bodies empty | Integration is in `after/ftplugin/gin-log.lua`, not hooks |
| stylua reformats output | Run stylua after converter; not part of byte-identical check |

## Next

P5 (`p5-init-lua.md`):

1. User removes `~/.config/rvpm/nvim` stub and runs `sh scripts/rvpm-link.sh`.
2. Replace bootloader path in `init.lua` with guarded `dofile(loader)`.
3. `rvpm sync` against real appname (137 plugins).
4. Measure startup with `rvpm profile` vs current `--startuptime`.

Consider adding skkeleton `on_map` to `rvpm/config.toml` if eager load is too heavy.
