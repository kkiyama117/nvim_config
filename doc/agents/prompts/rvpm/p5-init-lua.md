# omp prompt — P5: switch init.lua to the rvpm loader

You are working in `~/.config/nvim` (a git repo, branch `temp`).

Part of the dpp.vim → rvpm migration. Confirm reports P1–P4 all say
`STATUS: PASS` before starting. **This is the first phase that changes how
the user's real Neovim starts.** Be correspondingly careful.

## Context — read these, then stop reading

1. `doc/agents/plan-rvpm-bootloader.md` §4.1 (target `init.lua`, and the
   fate of every current block), §4.2 (cold start), §4.3 (why the rtp surgery
   goes), §2.5 (the author's own 11-line `init.lua`).
2. The current `~/.config/nvim/init.lua`.
3. `doc/agents/reports/rvpm-p4.md`.

## Goal

Replace the dpp bootstrap in `init.lua` with rvpm's guarded `dofile`, run the
first real `rvpm sync` of all 137 plugins, and measure startup.

## Target shape

```lua
vim.loader.enable()
local loader = vim.fn.expand("~/.cache/rvpm/nvim/plugins/loader.lua")
if vim.uv.fs_stat(loader) then
  dofile(loader)
end
```

Per the design doc §4.1, each current block of `init.lua` has a decided fate:

| Current block | Fate |
|---|---|
| `NVIM_CONFIG_HOME` / `NVIM_CACHE_HOME` env, `vimrc#is_debug`, `vimrc#augroup` | keep in `init.lua` — needed before plugins load |
| minimal `&rtp` list | delete |
| deno fallback (`g:denops#deno` when `deno` is off PATH) | move to `rvpm/plugins/github.com/vim-denops/denops.vim/before.lua` |
| `rtp:prepend my_nvim_bootloader` + `require(...).startup()` | delete — replaced by the guarded `dofile` |
| `packpath = ''`, `rtp:remove($VIMRUNTIME)`, `SourcePre`/`VimEnter` restore | **delete** — the loader sets `vim.go.loadplugins = false` at phase 1, which is the same guarantee; and the loader `dofile`s Lua files, which never fires `SourcePre`, so the restore is unreliable |
| `filetype plugin indent on`, `syntax on` | keep |

Setup that must run before plugins but does not belong in `init.lua` goes to
`rvpm/before.lua` (loader phase 3).

## Order of operations

1. **Back up first**: `git stash` is not enough — `init.lua` is tracked, so
   `git diff` is the record, but confirm the working tree is otherwise clean
   and note the current HEAD in the report.
2. Link the real config root: `sh scripts/rvpm-link.sh` (from P2). Resolve
   the stub `~/.config/rvpm/nvim/config.toml` blocker if it still exists — ask
   the user rather than deleting it yourself if the script refuses.
3. First real sync: `script -qec "rvpm sync" /dev/null` with **no**
   `RVPM_APPNAME` override. 137 plugins; expect minutes. Capture the
   `first-wins` merge-collision summary (design doc D7) — it matters.
4. Only then rewrite `init.lua`.
5. Measure. Compare against the dpp baseline.

Keep `~/.cache/nvim/dpp/` intact. It is the rollback path: restoring the old
`init.lua` must bring dpp back with no other action.

## Hard constraints

| Must not | Why |
|---|---|
| Delete `~/programs/nvim_plugins/my_nvim_bootloader` | P6. `init.lua` stops referencing it here, but the clone stays until Claude has reviewed |
| Delete `deps/*.toml`, `lua/hooks/*.dpp`, `denops/dpp.ts`, `~/.cache/nvim/dpp/` | P7. They are the rollback |
| Run `rvpm init --write` | write `init.lua` yourself, deliberately |
| `git commit` / `git push` | Claude reviews the working tree first |
| Leave the user with a Neovim that does not start | if it breaks and you cannot fix it in 3 attempts, restore `init.lua` from git and report FAIL |

## Environment rules

```sh
export RVPM_NO_AUTOUPDATE=1
```

`rvpm sync` needs a TTY: `script -qec "rvpm sync" /dev/null`. Do **not** set
`RVPM_APPNAME` in this phase — the real appname is `nvim`.

## Acceptance criteria

| # | Check |
|---|---|
| 1 | `nvim --headless -c 'qa!'` exits 0 with no errors on stderr |
| 2 | Plugin count loaded matches expectation; `rvpm doctor` reports `cloned plugins — N/N` and `init.lua loader hook — ok` |
| 3 | denops comes up: `denops#server#status()` reaches `running`, and skkeleton / ddu / ddc register (same assertions as P1, now against the real config) |
| 4 | A representative eager plugin and a representative lazy plugin both work: name them, trigger them, show the evidence |
| 5 | Startup time measured both ways: `nvim --startuptime` for the new config, and the recorded dpp baseline. Also run `rvpm profile --no-tui` |
| 6 | Rollback verified: `git checkout init.lua` restores a working dpp startup (test it, then re-apply your change) |

Criterion 6 is not optional. Prove the escape hatch before handing back.

## Deliverable report

`doc/agents/reports/rvpm-p5.md`, created first with `TODO` markers:

```markdown
# P5 report — init.lua switched to rvpm

STATUS: PASS | FAIL | BLOCKED | BUDGET EXHAUSTED

## HEAD before the change
sha + working tree state

## init.lua diff
the actual before/after, and the fate of each removed block

## First sync
duration, plugins cloned, failures, merge first-wins collisions (D7)

## Startup
| config | measurement | source |
dpp baseline vs rvpm, plus rvpm profile top offenders

## Acceptance
| # | check | result |

## Rollback
exactly how it was tested and that it worked

## Surprises
contradictions with the design doc, with section numbers

## Next
what P6 needs; anything still referencing dpp
```

## Anti-loop rules

1. Report file first, `TODO`-filled.
2. Budget 60 tool calls; at 40 write state into the report; at 60 stop with
   `STATUS: BUDGET EXHAUSTED`.
3. No file read twice.
4. Three failed attempts on one sub-question → `## Blocked`, move on. If the
   failure is "Neovim does not start", restore `init.lua` from git first,
   then report.

## Definition of done

Neovim starts on rvpm, denops plugins register, startup is measured against
the dpp baseline, and rollback is proven. Then stop — do not start P6.
