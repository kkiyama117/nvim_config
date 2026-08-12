# omp prompt — P2: rvpm layout bootstrap

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Part of the dpp.vim → rvpm migration. P1 has already proven that lazy denops
plugins register correctly — read `doc/agents/reports/rvpm-p1.md` to confirm
`STATUS: PASS` before doing anything. If it is not PASS, stop immediately.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §2.3 (why `config_root` cannot
   relocate `config.toml`), §3 (layout decision), §8 (decisions).
2. `doc/agents/reports/rvpm-p1.md`.

## Goal

Create the repo-side rvpm config root and the bootstrap that links it into
place, so that later phases have somewhere to write `config.toml` and hooks.

Target layout:

```
~/.config/rvpm/nvim  ->  ~/.config/nvim/rvpm/        (symlink)
                          ├── config.toml
                          ├── rvpm.lock              (generated later, committed)
                          ├── before.lua             (global hook, loader phase 3)
                          ├── after.lua              (global hook, loader phase 9)
                          └── plugins/github.com/<owner>/<repo>/{init,before,after}.lua
```

`config_root` stays **unset** in `config.toml` — it cannot relocate
`config.toml` itself (§2.3, measured), and the symlink makes it unnecessary.

## Deliverables

| Path | Content |
|---|---|
| `rvpm/config.toml` | `[options]` block only, no plugins yet (P3 fills it) |
| `rvpm/before.lua` | empty stub with a comment naming the phase |
| `rvpm/after.lua` | empty stub with a comment naming the phase |
| `scripts/rvpm-link.sh` | idempotent symlink bootstrap, see below |
| `.gitignore` | ignore nothing new unless justified — `rvpm.lock` **must be committed** |
| `doc/agents/reports/rvpm-p2.md` | report |

### `[options]` policy — set these explicitly, with a comment each

| Key | Value | Reason |
|---|---|---|
| `auto_update` | `"notify"` | default is `"install"`, which silently downloads and swaps the rvpm binary on every invocation (design doc D5) |
| `cooldown` | leave default `"1d"`, but comment it | `rvpm update` holds back commits younger than this; otherwise it looks like "no updates" (D6) |
| `concurrency` | `16` | matches the author's own config |
| `auto_clean` | your call, justify it in the report | deletes plugin dirs no longer in `config.toml` on every sync |

Do not set `config_root` or `cache_root`.

### `scripts/rvpm-link.sh`

Requirements:

- Resolve appname the way rvpm does: `$RVPM_APPNAME` → `$NVIM_APPNAME` → `nvim`.
- Link `~/.config/rvpm/<appname>` → the repo's `rvpm/` directory.
- **Idempotent**: re-running is a no-op.
- **Never destroys data**: if the target exists and is a real directory (not a
  symlink), refuse and print what to do. If it is already the correct symlink,
  say so and exit 0. If it is a symlink pointing elsewhere, refuse.
- Print the resulting state and exit non-zero on refusal.
- POSIX `sh` or `bash`; the user's shell is zsh but the script should not
  depend on it.

Note there is currently a **stub** `~/.config/rvpm/nvim/config.toml`
(75 bytes, `[options]` only) left by an earlier `rvpm init`. The script must
detect this case and tell the user to remove it rather than silently deleting
it — it is a real directory in the link's way.

## Hard constraints

| Must not | Why |
|---|---|
| Modify `~/.config/nvim/init.lua` | P5 owns it |
| Modify `deps/*.toml`, `lua/hooks/*` | P3/P4 own them |
| Add plugins to `rvpm/config.toml` | P3 owns that |
| Delete `~/.config/rvpm/nvim/` yourself | the script reports; the user decides |
| Delete `~/programs/nvim_plugins/my_nvim_bootloader` | P6 owns it |
| `git commit` / `git push` | Claude reviews the working tree first |

Leave the `nvim-rvpm` test appname from P1 alone — later phases reuse it.

## Environment rules

```sh
export RVPM_NO_AUTOUPDATE=1
```

`rvpm sync` needs a TTY: `script -qec "rvpm sync" /dev/null`.

## Acceptance criteria

| # | Check |
|---|---|
| 1 | `sh scripts/rvpm-link.sh` on a clean machine state creates the symlink and exits 0 |
| 2 | Running it a second time exits 0 and changes nothing |
| 3 | With a real directory in the way, it refuses, exits non-zero, and explains |
| 4 | With `RVPM_APPNAME=nvim-rvpm` set, it targets `~/.config/rvpm/nvim-rvpm` — appname isolation is intact |
| 5 | `RVPM_NO_AUTOUPDATE=1 rvpm doctor` finds `rvpm/config.toml` through the symlink and reports `0/0` plugins without error |

Test case 3 must be exercised against a scratch path, **not** by damaging the
real `~/.config/rvpm/nvim/`.

## Deliverable report

`doc/agents/reports/rvpm-p2.md`, created first with `TODO` markers:

```markdown
# P2 report — layout bootstrap

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## What was created
paths + one line each

## [options] choices
table: key, value, reason

## scripts/rvpm-link.sh
behaviour matrix: state before → action → exit code

## Acceptance
| # | check | result |

## Surprises
contradictions with the design doc, with section numbers

## Next
what P3 needs
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 60 tool calls; at 40 write state into the report; at 60 stop with
   `STATUS: BUDGET EXHAUSTED`.
3. No file read twice.
4. Three failed attempts on one sub-question → `## Blocked`, move on.

## Definition of done

The five acceptance checks have real results in the report, and
`sh scripts/rvpm-link.sh` is safe to run twice. Then stop — do not start P3.
