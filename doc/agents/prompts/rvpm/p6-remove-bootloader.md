# omp prompt — P6: remove the local bootloader clone

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Part of the dpp.vim → rvpm migration. Confirm `doc/agents/reports/rvpm-p5.md`
says `STATUS: PASS` before starting. This phase is small and destructive —
its whole value is doing the checks in the right order.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §9 row P6 (the preconditions), §8 Q2.
2. `doc/agents/reports/rvpm-p5.md`.

## Goal

Delete `~/programs/nvim_plugins/my_nvim_bootloader` from the local machine,
keeping the GitHub remote as the archive.

## What is already true (verify, do not assume)

- Remote: `git@github.com:kkiyama117/my_nvim_bootloader.git`
- The Quint specs were committed and pushed as `0c93369`
  (`docs(specs): add Quint model of the boot/recovery and auto_update flows`)
  and verified present on the remote. **The remote is a complete archive.**
- P5 removed `require('my_nvim_bootloader').startup()` from `init.lua`, so
  nothing loads it any more.

## Preconditions — all must hold before `rm`

Check each and record the command output in the report. If any fails, stop
and report; do not "fix" it by deleting anyway.

| # | Precondition | How to check |
|---|---|---|
| 1 | No uncommitted changes in the bootloader repo | `git -C <repo> status --porcelain` is empty |
| 2 | No unpushed commits | `git -C <repo> log --oneline @{u}..HEAD` is empty |
| 3 | Local `main` == `origin/main` | `git -C <repo> status -sb` shows no ahead/behind |
| 4 | The remote really has the content | `gh api repos/kkiyama117/my_nvim_bootloader/contents/specs` lists both `.qnt` files; also confirm `lua/` and `plugin/` are present on the remote |
| 5 | Nothing in `~/.config/nvim` references the plugin any more | `grep -rn "my_nvim_bootloader" ~/.config/nvim --exclude-dir=.git` returns only documentation hits (`doc/agents/**`, `README.md`) |
| 6 | Neovim starts without it | temporarily rename the directory, run `nvim --headless -c 'qa!'`, confirm exit 0 and no errors, then proceed to the real delete |

Precondition 6 is the real test: rename first (`mv <dir> <dir>.tobedeleted`),
verify, and only then remove. Never `rm -rf` as the first action.

## Also in scope

- `denops/dpp.ts:194` scans `~/programs/nvim_plugins` via `dpp-ext-local`.
  That file is deleted in P7, so leave it alone here — but note in the report
  that after this phase the directory is **empty**, since the bootloader was
  its only entry.
- Per the design doc §8 Q1, future local plugins use rvpm `dev = true` with an
  explicit `dst`. Nothing to migrate now; just confirm the directory is empty
  and say so.
- Update `README.md`'s install section only if it still tells the user the
  bootloader will install things. If it does, the correct new text is
  "`rvpm sync`, then `nvim`" (design doc §4.2). If P5 already did this, say so
  and change nothing.

## Hard constraints

| Must not | Why |
|---|---|
| Delete anything under `~/.cache/nvim/dpp/` | P7; still the rollback |
| Delete `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts` | P7 |
| Force-push or rewrite history on the bootloader remote | it is the archive |
| `rm -rf` before the rename-and-verify step | precondition 6 |
| `git commit` / `git push` in the nvim repo | Claude reviews the working tree first |

## Acceptance criteria

| # | Check |
|---|---|
| 1 | All six preconditions recorded with real command output |
| 2 | `~/programs/nvim_plugins/my_nvim_bootloader` no longer exists locally |
| 3 | `~/programs/nvim_plugins/` is empty (or its remaining contents are listed) |
| 4 | `nvim --headless -c 'qa!'` exits 0 |
| 5 | The GitHub remote still resolves and still lists `specs/`, `lua/`, `plugin/` |
| 6 | `grep -rn "my_nvim_bootloader" ~/.config/nvim --exclude-dir=.git` returns only doc hits |

## Deliverable report

`doc/agents/reports/rvpm-p6.md`, created first with `TODO` markers:

```markdown
# P6 report — local bootloader clone removed

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## Preconditions
| # | check | command | output | pass? |

## What was deleted
path, size, last commit sha it was at

## Remote archive
proof it still holds everything

## Acceptance
| # | check | result |

## Remaining references
grep output, and whether each is expected

## Next
what P7 needs
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 30 tool calls for this phase — it is small. At 30, stop.
3. No file read twice.
4. If a precondition fails, that is a result, not a problem to solve. Record
   it and stop.

## Definition of done

The clone is gone, the remote is intact, Neovim starts, and the six
preconditions are documented with real output. Then stop — do not start P7.
