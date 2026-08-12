# omp prompt — P7: remove dpp from the repo

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Final phase of the dpp.vim → rvpm migration. Confirm
`doc/agents/reports/rvpm-p6.md` says `STATUS: PASS` before starting.

This phase burns the rollback path. Do not start it until the user has been
running on rvpm long enough to be confident — if that has not happened, say
so and stop.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §9 row P7, §6 D4 (the `.dpp` editor
   tooling), §2.1 (what the dpp chain was).
2. `doc/agents/reports/rvpm-p5.md` and `rvpm-p6.md`.

## Goal

Delete every dpp artifact from the repo and update the docs that describe the
old architecture.

## Scope

| Target | Action |
|---|---|
| `deps/*.toml` (14 files, 137 entries) | delete — superseded by `rvpm/config.toml` |
| `lua/hooks/*.dpp` (35 files) | delete — superseded by `rvpm/plugins/**` |
| `denops/dpp.ts`, `denops/dpp/` | delete |
| `denops/deno.json` | check whether anything else in `denops/` still needs it before deleting |
| `~/.cache/nvim/dpp/` | delete (outside the repo; confirm with the user first — it is ~100+ clones) |
| `after/ftplugin/dpp.lua` | delete — `.dpp` filetype no longer exists (D4) |
| `after/queries/dpp/*` | delete (D4) |
| `ftdetect/` entry for `.dpp`, if any | delete |
| `syntax/` entry for `.dpp`, if any | delete |
| `doc/agents/plan-dpp-viml-emmylua-bridge.md` | mark obsolete — do not silently delete a planning doc; add a `Status: obsolete (superseded by plan-rvpm-bootloader.md, dpp removed in P7)` header |
| kakehashi `tree-sitter-dpp` bridge (`~/.config/kakehashi/`, chezmoi-managed) | **out of scope** — report what would need doing, change nothing |

## Docs to update

| File | Change |
|---|---|
| `AGENTS.md` | §1 "Main plugins" table: `Plugin manager` row `dpp.vim` → `rvpm`. The `External runtime` row (deno) stays — denops plugins still need it, but say it is no longer needed by the plugin manager |
| `README.md` | install section: the bootloader story → `rvpm sync`, then `nvim` (design doc §4.2). If P6 already did this, verify and leave it |
| `doc/kkiyama117-nvim.jax` and other vimdoc | update any dpp references. Per `AGENTS.md` rule 01, user-facing docs are vimdoc — keep them vimdoc |
| `doc/agents/plan-rvpm-bootloader.md` | add a final section recording that the migration completed, with the P5 startup numbers |

## Hard constraints

| Must not | Why |
|---|---|
| Delete `~/.cache/nvim/dpp/` without asking the user | it is 100+ clones and outside the repo |
| Delete `doc/agents/plan-dpp-viml-emmylua-bridge.md` | mark it obsolete instead; planning history has value |
| Touch `~/.config/kakehashi/` or the chezmoi source tree | out of scope; report only |
| Rewrite unrelated config while you are in there | scope creep; this is a deletion phase |
| `git commit` / `git push` | Claude reviews the working tree first |

## Acceptance criteria

| # | Check |
|---|---|
| 1 | `grep -rni "dpp" ~/.config/nvim --exclude-dir=.git` returns only intentional hits: `doc/agents/**` history, the obsolete-marked plan doc, and this prompt set. List every remaining hit and justify it |
| 2 | `nvim --headless -c 'qa!'` exits 0 |
| 3 | `RVPM_NO_AUTOUPDATE=1 rvpm doctor` clean |
| 4 | Opening a Lua file, a TypeScript file, and a Markdown file in Neovim produces no errors (the deleted ftplugin/queries broke nothing) |
| 5 | `AGENTS.md` plugin-manager row says rvpm |
| 6 | `git status` shows only deletions and the doc edits described above — no surprise files |

## Deliverable report

`doc/agents/reports/rvpm-p7.md`, created first with `TODO` markers:

```markdown
# P7 report — dpp removed

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## Deleted
table: path, kind, size/count

## Kept deliberately
table: path, why

## Docs updated
table: file, what changed

## Remaining "dpp" hits
grep output with a justification per line

## Out of scope, needs the user
kakehashi tree-sitter-dpp bridge: what would need doing
~/.cache/nvim/dpp/: deleted or awaiting approval

## Acceptance
| # | check | result |

## Migration summary
plugins migrated, startup before/after, total phases, anything still owed
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 60 tool calls; at 40 write state into the report; at 60 stop with
   `STATUS: BUDGET EXHAUSTED`.
3. No file read twice.
4. Three failed attempts on one sub-question → `## Blocked`, move on.

## Definition of done

No dpp artifacts remain except justified documentation history, Neovim starts
clean, docs describe rvpm, and the report carries the migration summary.
