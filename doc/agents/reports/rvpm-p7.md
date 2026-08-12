# P7 report — dpp removed

STATUS: PASS

## Deleted

| Path | Kind | Count/size |
|------|------|------------|
| `deps/*.toml` | dpp plugin lists | 14 files |
| `lua/hooks/*.dpp` | dpp hook files | 36 files |
| `lua/hooks/shared/*.dpp` | shared dpp hooks | 2 files (converted `.lua` kept) |
| `denops/dpp.ts`, `denops/dpp/` | dpp denops config | 2 paths |
| `after/ftplugin/dpp.lua` | `.dpp` ftplugin (D4) | 1 file |
| `after/queries/dpp/` | tree-sitter queries (D4) | 2 files |
| `ftdetect/dpp.vim`, `syntax/dpp.vim` | `.dpp` filetype (D4) | 2 files |

Also removed from live config:

- `denops/deno.json` — dropped `@shougo/dpp-*` imports (ddu/ddc/ddt imports kept)
- `denops/ddu.ts` — removed `dpp` ddu source and `DppAction` type
- `rvpm/.../ddu.vim/init.lua` — removed `[DP]l` dpp plugin list keymap
- `lua/vimrc/kakehashi_config.lua` — removed `dpp` filetype + `languages.dpp` bridge
- `after/lsp/kakehashi.lua` — removed `filetype == 'dpp'` on_attach branch

Migration converters moved (not deleted): `scripts/dpp2rvpm.py`, `scripts/dpp-hooks2rvpm.py` → `doc/agents/scripts/`.

## Kept deliberately

| Path | Why |
|------|-----|
| `~/.cache/nvim/dpp/` | **User request** — 247M rollback cache retained |
| `lua/hooks/shared/{ddc_skkeleton,ddu_gin}.lua` | live shared modules (P4) |
| `lua/hooks/heirline_components/` | live statusline modules |
| `denops/{ddu,ddc,ddt,consts}.ts`, `denops/deno.json` | denops plugin configs still used |
| `doc/agents/scripts/dpp*.py` | migration history / re-runnable converters |

## Docs updated

| File | Change |
|------|--------|
| `AGENTS.md` | plugin manager → rvpm; deno note clarified |
| `README.md` | already `rvpm sync` from P6 — verified |
| `doc/kkiyama117-nvim.jax` | full rewrite for rvpm layout/install |
| `doc/kkiyama117-nvim-lsp.jax` | rvpm hook paths; dpp filetype marked obsolete |
| `doc/kkiyama117-nvim-statusline.jax` | heirline hook path |
| `doc/agents/plan-dpp-viml-emmylua-bridge.md` | obsolete header |
| `doc/agents/plan-rvpm-bootloader.md` | migration completed section + P5 numbers |
| `.emmyrc.json` | `requirePattern` → rvpm hooks; drop `*.dpp` |

## Remaining "dpp" hits

| Location | Justification |
|----------|---------------|
| `doc/agents/**` | migration reports, prompts, converters, plan history |
| `doc/agents/plan-dpp-viml-emmylua-bridge.md` | marked obsolete; planning archive |
| `doc/kkiyama117-nvim-lsp.jax` | obsolete section documenting removal |
| `p1-context.md` | agent scratch (not loaded by Neovim) |
| `$XDG_DATA_HOME/pueue/state.json` | staged artifact; env paths reference old dpp cache (not config) |

No hits in live startup path (`init.lua`, `rvpm/`, `lua/vimrc/`, `denops/` except doc comments in agents tree).

## Out of scope, needs the user

**kakehashi `tree-sitter-dpp` bridge** (`~/.config/kakehashi/parser/dpp.so`, chezmoi tree): grammar and parser remain on disk but nothing in this config references `.dpp` files anymore. Optional cleanup: remove parser from kakehashi.toml / chezmoi when convenient.

**`~/.cache/nvim/dpp/`**: kept per user request (247M). Safe to delete manually when no longer wanted.

## Acceptance

| # | check | result |
|---|-------|--------|
| 1 | grep hits justified | **PASS** — only doc/agents, obsolete plan, vimdoc obsolete note, agent scratch |
| 2 | headless nvim | **PASS** — exit 0 |
| 3 | rvpm doctor | **PASS** — 129/129, 0 errors (2 pre-existing warnings) |
| 4 | filetype smoke | **PASS** — lua, typescript, markdown open without error |
| 5 | AGENTS.md rvpm | **PASS** |
| 6 | git status scope | **PASS** — deletions + doc edits + rvpm hook comment cleanup; no surprise new config |

## Migration summary

| Item | Value |
|------|-------|
| Phases | P1–P7 complete |
| Plugins | 137 dpp → 129 rvpm |
| Startup | dpp 81.6 ms → rvpm 64.7 ms (`--startuptime`) |
| rvpm profile | 37.6 ms |
| Bootloader | deleted locally (P6); GitHub archive kept |
| Rollback | repo artifacts removed; `~/.cache/nvim/dpp/` kept on disk |
| Still owed | commit review; optional kakehashi dpp parser cleanup; `rvpm.lock` commit decision |

Migration complete. Neovim runs on rvpm; dpp config surface removed from the repo.
