# Claude review — P4: .dpp hooks → rvpm per-plugin hooks

Read `doc/agents/prompts/rvpm/review/README.md` first. Then this.

## What P4 was supposed to produce

35 `lua/hooks/*.dpp` files converted into `rvpm/plugins/github.com/<owner>/<repo>/{init,before,after}.lua`,
via a re-runnable script. Surveyed input: **58 sections total** — `lua_source`
29, `lua_add` 26, `hook_source` 2, `hook_add` 1, no `post_source` anywhere
(design doc §5.2).

Mapping: `*_add` → `init.lua` (phase 4, pre-rtp); `*_source` → `before.lua`
(rtp appended, `plugin/*` not yet sourced — timing identical to dpp's
`hook_source`).

## Read

1. `doc/agents/reports/rvpm-p4.md`
2. `doc/agents/prompts/rvpm/p4-hooks.md` and design doc §5.2, §2.5
3. `scripts/dpp-hooks2rvpm.*` and a sample of the generated tree
4. `doc/agents/reports/rvpm-review-log.md`

## The traps

| # | Trap | How to detect |
|---|---|---|
| 1 | **Sections lost.** 58 in; every one lands somewhere or is listed as dropped | Count the fold markers yourself: `grep -c '{{{' lua/hooks/*.dpp lua/hooks/shared/*.dpp`. Compare to the report's accounting |
| 2 | **Refactored instead of translated.** The prompt said translation, not improvement | Spot-check 3 hooks against their `.dpp` source line by line. Reworded logic, "while I was here" cleanups, or reordered statements are findings even when they look better |
| 3 | **Generated Lua never syntax-checked** | Check it yourself across the whole tree: `for f in $(find rvpm/plugins -name '*.lua'); do luajit -bl "$f" /dev/null >/dev/null || echo "SYNTAX: $f"; done` (or `loadfile` via `nvim -l`). Never *execute* them |
| 4 | **Shared hooks duplicated instead of shared** | `ddc_skkeleton` and `ddu_gin` must become modules under `lua/hooks/shared/*.lua`, required from both consumers. Copy-pasted bodies in two places will drift |
| 5 | **`lua << EOF` heredocs mangled** | Only 3 sections are Vim-script, all in the two shared files. Read those two conversions in full — they are the hardest and the least covered by pattern-matching |
| 6 | **denops readiness idiom missing** | Any hook calling a denops plugin's functions must guard with `denops#plugin#is_loaded` / `User DenopsPluginPost:<name>` (design doc §2.5). Grep the generated tree for `skkeleton#`, `ddu#`, `ddc#`, `gin#` calls and check each is guarded or justified |
| 7 | **Blocks moved to `after.lua` without cause** | There were no `post_source` sections. Every `after.lua` is a judgement call and needs its reason in the report |
| 8 | **Input mutated** | `git diff lua/hooks/ deps/` must be empty — they stay as the dpp fallback until P7 |
| 9 | **Converter not deterministic** | Re-run to a temp dir and `diff -r` |
| 10 | **Formatter skipped** | If `.stylua.toml` exists, generated files should conform; a repo-wide format check that now fails is a finding |

## Reproduce

```sh
export RVPM_NO_AUTOUPDATE=1
grep -c '{{{' lua/hooks/*.dpp lua/hooks/shared/*.dpp | awk -F: '{s+=$2} END{print "sections:", s}'
find rvpm/plugins -name '*.lua' | wc -l
git diff --stat lua/hooks/ deps/          # must be empty
rvpm doctor
```

Pick the two shared-hook conversions and one large single-plugin hook
(`skkeleton.dpp` is the biggest and the most denops-sensitive) and read them
end to end against the originals.

## Acceptance to confirm

| # | Criterion |
|---|---|
| 1 | all 58 sections accounted for |
| 2 | every generated file parses |
| 3 | both `[[multiple_hooks]]` resolved via a shared module, both consumers reference it |
| 4 | `rvpm doctor` still clean |
| 5 | converter deterministic |
| 6 | every denops-touching hook guarded or justified |

## Write back

- Design doc §5.2: replace the survey with what the conversion actually
  found — especially any section type or format the survey missed.
- If the readiness idiom turned out to be needed more widely than §2.5
  suggests, say so in §6 D-series: it changes the maintenance story for the
  ~80 denops plugins.
- Record the shared-module API (`require("hooks.shared.x").setup()` or
  whatever was chosen) in §5.2 so P7 does not delete something still in use.
- Append the review-log row.
