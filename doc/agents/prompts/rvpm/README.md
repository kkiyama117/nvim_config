# omp prompts — dpp → rvpm migration

Prompts for running the migration with [omp](https://github.com/can1357/oh-my-pi)
(oh-my-pi) instead of by hand. Each phase is one omp session. Claude reviews
the report between phases.

## Usage

```sh
cd ~/.config/nvim
omp @doc/agents/prompts/rvpm/p1-denops-lazy-proof.md
```

One phase per session. Do **not** chain phases in a single session — the
review gate between them is the point.

## Flow

```
P1 proof ──▶ review ──▶ P2 layout ──▶ review ──▶ P3 config.toml ──▶ review
                                                                      │
   P7 cleanup ◀── review ◀── P6 delete ◀── review ◀── P5 init.lua ◀───┤
                                                                      │
                                              P4 hooks ◀──────────────┘
```

| Phase | Prompt | Deliverable | Gate |
|---|---|---|---|
| P1 | `p1-denops-lazy-proof.md` | `doc/agents/reports/rvpm-p1.md` | lazy denops proven, or migration aborted |
| P2 | `p2-layout-bootstrap.md` | `rvpm/` dir + `scripts/rvpm-link.sh` | symlink works, appname isolation intact |
| P3 | `p3-config-toml.md` | `rvpm/config.toml` (137 plugins) + converter | every `deps/*.toml` field accounted for |
| P4 | `p4-hooks.md` | `rvpm/plugins/**/{init,before,after}.lua` | all 35 `.dpp` files converted |
| P5 | `p5-init-lua.md` | new `init.lua` | nvim starts, startup time measured |
| P6 | `p6-remove-bootloader.md` | bootloader gone | nvim still starts |
| P7 | `p7-cleanup.md` | dpp artifacts gone | repo has no dpp references |

P1 is a hard gate: if lazy denops plugins cannot be made to work, stop and
report — the rest of the plan is void.

## Shared rules (every phase)

These are repeated inside each prompt; listed here so they can be changed in
one place.

| Rule | Reason |
|---|---|
| Source of truth is `doc/agents/plan-rvpm-bootloader.md` | It records what was already verified. Do not re-derive it |
| Always `export RVPM_NO_AUTOUPDATE=1` | `options.auto_update` defaults to `"install"`; rvpm otherwise self-updates its binary on every invocation |
| `rvpm sync` needs a TTY | Non-TTY fails with `Error: No such device or address (os error 6)`. Use `script -qec "rvpm sync" /dev/null` |
| Never run `rvpm init --write` | It appends a `dofile` line to the real `init.lua`. P5 owns that file |
| Never touch `~/.config/rvpm/nvim/` before P5 | That is the real appname. P1–P4 work under `nvim-rvpm` or in the repo |
| Never delete `~/programs/nvim_plugins/my_nvim_bootloader` before P6 | `init.lua:76` still requires it; deleting it early means zero plugins load |
| Commit nothing unless the prompt says so | Claude reviews the working tree |

## Anti-loop rules (every phase)

A previous agent session spent 2h53m on this migration and produced **zero
file edits** — it looped re-reading the same files. Every prompt therefore
carries these limits:

1. **Write the report file first**, with the headings filled and findings
   marked `TODO`. Update it as you go. Never leave reporting to the end.
2. **Budget: 60 tool calls per phase.** At 40, write current state to the
   report. At 60, stop and write `STATUS: BUDGET EXHAUSTED` with what is
   known and what remains.
3. **No file gets read twice.** If you need it again, it should already be
   summarised in the report.
4. If one sub-question resists 3 attempts, write it under `## Blocked` with
   what you tried, and move to the next item. Do not keep digging.
5. Prefer one decisive experiment over five reads of source code.

## Review gate

After each phase, Claude reviews against the matching prompt in `review/`:

> Review P1: read `doc/agents/prompts/rvpm/review/r1-denops-lazy-proof.md`
> and follow it.

| omp phase | review prompt |
|---|---|
| P1 | `review/r1-denops-lazy-proof.md` |
| P2 | `review/r2-layout-bootstrap.md` |
| P3 | `review/r3-config-toml.md` |
| P4 | `review/r4-hooks.md` |
| P5 | `review/r5-init-lua.md` |
| P6 | `review/r6-remove-bootloader.md` |
| P7 | `review/r7-cleanup.md` |

Each review prompt carries the phase's specific traps — the ways a report can
claim success while measuring the wrong thing — and ends by writing findings
back into `doc/agents/plan-rvpm-bootloader.md` and
`doc/agents/reports/rvpm-review-log.md`. Claude sessions do not persist; those
two files are the migration's memory. See `review/README.md` for the
reviewer's standing rules.
