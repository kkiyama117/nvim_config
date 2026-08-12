# omp prompt — P3: convert deps/*.toml to rvpm config.toml

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Part of the dpp.vim → rvpm migration. Confirm `doc/agents/reports/rvpm-p1.md`
and `rvpm-p2.md` both say `STATUS: PASS` before starting. If not, stop.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §5.1 (field mapping table — **use it,
   do not re-derive it**), §6 (risks D2/D3/D5–D8).
2. `deps/*.toml` — 14 files, 137 `[[plugins]]` entries. This is the input.
3. `rvpm/config.toml` — created by P2, `[options]` only. This is the output.

Do **not** read `lua/hooks/*.dpp` in this phase. Hooks are P4. You only carry
the `hooks_file` path forward as a note for P4.

## Goal

Produce `rvpm/config.toml` containing all 137 plugins, plus a conversion
script that produced it, plus an explicit accounting of every dpp field that
could not be mapped.

Write a **script** (`scripts/dpp2rvpm.<ext>`, language your choice — python3,
deno, and rust are all available) rather than hand-converting 137 entries.
The script is a deliverable: it must be re-runnable so the conversion can be
regenerated after a fix, and it must print a report of unmapped fields.

## The mapping (from the design doc §5.1 — authoritative)

| dpp | n | rvpm |
|---|---|---|
| `repo` | 137 | `url` |
| `group` | 85 | *(no equivalent — drop, but count them)* |
| `hooks_file` | 35 | *(P4 — record the mapping, emit nothing)* |
| `on_event` | 16 | `on_event` |
| `depends` | 15 | `depends` |
| `on_source` | 9 | `on_source` |
| `lazy` | 7 | `lazy` |
| `on_ft` | 6 | `on_ft` |
| `on_map` | 3 | `on_map` |
| `external_commands` | 3 | `cond` — **not `build`**. dpp skips sourcing when the command is not `executable()` (`dpp.vim/autoload/dpp/source.vim:138`), so emit `cond = "vim.fn.executable('x') == 1"` |
| `if` | 2 | `cond` (runtime) — e.g. `if = 'exists("$MOCWORD_DATA")'` → `cond = "vim.env.MOCWORD_DATA ~= nil"` |
| `denops_wait` | 2 | *(drop — rvpm's `load_lazy` calls `denops#plugin#wait` itself)* |
| `rtp = ""` | 2 | *(drop — dpp-only)* |
| `on_if` | 1 | `cond` |
| `on_lua` | 1 | **gap — see D2 below** |
| `on_post_source` | 1 | `on_source` |
| `on_cmd` | 1 | `on_cmd` |
| `name` | 1 | `name` |

Two constructs need care:

- **`[[multiple_hooks]]`** (2 occurrences, `deps/ddc.toml:154` and one in
  `deps/ddu.toml`) — dpp-ext-toml's "one hooks file shared by several
  plugins", e.g. `plugins = ["ddc.vim", "skkeleton"]`. rvpm has no
  equivalent. Emit nothing here; record both for P4, which will resolve them
  with a shared Lua module under `lua/hooks/shared/`.
- **`on_lua = "agentic"`** (`deps/ai.toml`) — rvpm has no `on_lua`. Decide
  between eager, `on_cmd`, or `on_event`, and justify it in the report (D2).

## Plugins that must not become lazy

The dpp stack itself is being deleted, not migrated. **Do not emit** entries
for: `Shougo/dpp.vim`, `Shougo/dpp-ext-*`, or anything whose only purpose is
dpp. List what you dropped and why in the report.

`vim-denops/denops.vim` stays, eager.

## Hard constraints

| Must not | Why |
|---|---|
| Modify `deps/*.toml` | it is the input, and the fallback if this goes wrong |
| Modify `lua/hooks/*` | P4 |
| Modify `init.lua` | P5 |
| Run `rvpm sync` against the **real** appname | use `RVPM_APPNAME=nvim-rvpm`; cloning 137 plugins into the real cache is P5's business |
| Invent plugins, versions, or `rev` pins | convert what exists |
| `git commit` / `git push` | Claude reviews the working tree first |

## Environment rules

```sh
export RVPM_NO_AUTOUPDATE=1
```

`rvpm sync` needs a TTY: `script -qec "rvpm sync" /dev/null`.

## Acceptance criteria

| # | Check |
|---|---|
| 1 | `rvpm/config.toml` parses: `RVPM_NO_AUTOUPDATE=1 rvpm doctor` reports no config errors |
| 2 | Plugin count reconciles: 137 input entries = emitted + dropped, with every drop justified by name |
| 3 | `rvpm doctor` reports `depends cycles — none`, `depends references — N/N resolved`, `on_source typos — none`, `duplicates — none` |
| 4 | Every `hooks_file` (35) appears in a P4 handoff table: dpp path → rvpm per-plugin hook directory |
| 5 | The conversion script re-runs and produces a byte-identical `config.toml` |
| 6 | Unmapped-field report is empty **or** every entry has a decision recorded |

Do not run a full `rvpm sync` of all 137 plugins in this phase. Validation is
`rvpm doctor` (static) only — cloning is P5.

## Deliverable report

`doc/agents/reports/rvpm-p3.md`, created first with `TODO` markers:

```markdown
# P3 report — deps/*.toml → rvpm/config.toml

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## Counts
input entries / emitted / dropped (with reasons) — must reconcile to 137

## Field mapping applied
table: dpp field, n, rvpm field, notes on any judgement call

## Decisions
- on_lua (agentic.nvim) → ?  why
- [[multiple_hooks]] ×2 → handed to P4, listed
- external_commands ×3 → the exact cond expressions emitted
- if / on_if → the exact cond expressions emitted

## Dropped plugins
table: repo, reason

## Hooks handoff for P4
table: plugin url, dpp hooks_file, target rvpm hook dir

## Acceptance
| # | check | result |

## Surprises
contradictions with the design doc, with section numbers to correct

## Next
what P4 needs
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 60 tool calls; at 40 write state into the report; at 60 stop with
   `STATUS: BUDGET EXHAUSTED`.
3. No file read twice — the conversion script reads the tomls, you do not.
4. Three failed attempts on one sub-question → `## Blocked`, move on.
5. Write the script early and iterate on its output. Do not read 14 toml
   files by hand first.

## Definition of done

`rvpm/config.toml` has 137 entries accounted for, `rvpm doctor` is clean, the
converter re-runs deterministically, and the P4 handoff table is complete.
Then stop — do not start P4.
